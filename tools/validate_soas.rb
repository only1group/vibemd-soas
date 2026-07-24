#!/usr/bin/env ruby
# frozen_string_literal: true

require "csv"
require "date"
require "json"
require "pathname"
require "set"
require "yaml"

module SOASValidation
  ROOT = Pathname.new(__dir__).join("..").expand_path
  PACKAGE = ROOT.join(".soas")
  CAPABILITY_ID = /\ASOAS-[A-Z0-9]+(?:-[A-Z0-9]+)*\z/
  SEMVER = /\A\d+\.\d+\.\d+\z/
  OUTCOMES = %w[satisfied finding-raised insufficient-evidence not-executed not-applicable blocked].freeze
  REQUIRED_CAPABILITY_FIELDS = %w[
    id name version category purpose profiles scopes scope_signals inputs
    control_objectives evidence inspection_procedures test_recipes failure_modes
    outputs exit_criteria frameworks dependencies questions severity_considerations
  ].freeze

  Result = Struct.new(:errors, :facts, keyword_init: true) do
    def success?
      errors.empty?
    end
  end

  module_function

  def type_matches?(value, type)
    case type
    when "object" then value.is_a?(Hash)
    when "array" then value.is_a?(Array)
    when "string" then value.is_a?(String)
    when "integer" then value.is_a?(Integer)
    when "number" then value.is_a?(Numeric)
    when "boolean" then value == true || value == false
    when "null" then value.nil?
    else true
    end
  end

  # Dependency-free validation for the JSON Schema vocabulary used by SOAS.
  # It intentionally fails closed on contracts authored by this repository and
  # keeps SOAS itself runtime-free.
  def schema_errors(instance, schema, location = "$")
    errors = []
    if schema.key?("type")
      types = Array(schema["type"])
      unless types.any? { |type| type_matches?(instance, type) }
        return ["#{location}: expected #{types.join(' or ')}, got #{instance.class}"]
      end
    end
    errors << "#{location}: value not in enum" if schema.key?("enum") && !schema["enum"].include?(instance)
    errors << "#{location}: value does not equal const" if schema.key?("const") && instance != schema["const"]
    if instance.is_a?(String)
      errors << "#{location}: shorter than minLength" if schema["minLength"] && instance.length < schema["minLength"]
      errors << "#{location}: does not match pattern" if schema["pattern"] && !Regexp.new(schema["pattern"]).match?(instance)
      if schema["format"] == "date-time"
        begin
          DateTime.iso8601(instance)
        rescue ArgumentError
          errors << "#{location}: invalid date-time"
        end
      end
    end
    if instance.is_a?(Array)
      errors << "#{location}: fewer than minItems" if schema["minItems"] && instance.length < schema["minItems"]
      errors << "#{location}: items must be unique" if schema["uniqueItems"] && instance.uniq.length != instance.length
      instance.each_with_index { |item, index| errors.concat(schema_errors(item, schema["items"], "#{location}[#{index}]")) } if schema["items"]
    end
    if instance.is_a?(Hash)
      Array(schema["required"]).each { |key| errors << "#{location}: missing required property #{key}" unless instance.key?(key) }
      properties = schema.fetch("properties", {})
      instance.each do |key, value|
        if properties.key?(key)
          errors.concat(schema_errors(value, properties[key], "#{location}.#{key}"))
        elsif schema["additionalProperties"] == false
          errors << "#{location}: unknown property #{key}"
        end
      end
    end
    Array(schema["allOf"]).each do |subschema|
      errors.concat(schema_errors(instance, subschema, location))
    end
    if schema["if"] && schema_errors(instance, schema["if"], location).empty? && schema["then"]
      errors.concat(schema_errors(instance, schema["then"], location))
    end
    errors
  end

  def load_yaml(path)
    YAML.safe_load(path.read, permitted_classes: [Date], aliases: false)
  rescue Psych::Exception => e
    raise "#{path.relative_path_from(ROOT)}: invalid YAML: #{e.message}"
  end

  def framework_references(value, location = "$", references = [])
    case value
    when Hash
      value.each do |key, child|
        child_location = "#{location}.#{key}"
        if %w[normative advisory conditional].include?(key)
          Array(child).each_with_index do |identifier, index|
            references << [identifier, "#{child_location}[#{index}]"] if identifier.is_a?(String)
          end
        else
          framework_references(child, child_location, references)
        end
      end
    when Array
      value.each_with_index { |child, index| framework_references(child, "#{location}[#{index}]", references) }
    end
    references
  end

  def standards_integrity_errors(registry, documents:, overlay_ids:)
    errors = []
    standards = Array(registry["standards"])
    standard_ids = standards.map { |standard| standard["id"] }
    errors << "standards registry: duplicate ids" unless standard_ids.uniq.length == standard_ids.length
    registered = standard_ids.to_set

    standards.each do |standard|
      %w[id name authority pinned_version status official_source resolution].each do |field|
        errors << "standards registry #{standard['id']}: missing #{field}" unless standard.key?(field)
      end
      %w[resolved_on online_resolution snapshot].each do |field|
        errors << "standards registry #{standard['id']}: resolution missing #{field}" unless standard.fetch("resolution", {}).key?(field)
      end
    end

    documents.each do |source, document|
      framework_references(document).each do |identifier, location|
        next if registered.include?(identifier) || overlay_ids.include?(identifier)
        errors << "#{source}: unresolved standard #{identifier} at #{location}"
      end
    end
    errors
  end

  def resolve_standard_offline(registry, identifier)
    matches = Array(registry["standards"]).select { |standard| standard["id"] == identifier }
    raise "duplicate standard #{identifier}" if matches.length > 1
    raise "unknown standard #{identifier}" if matches.empty?

    standard = matches.first
    {
      "id" => standard["id"],
      "pinned_version" => standard["pinned_version"],
      "status" => standard["status"],
      "official_source" => standard["official_source"],
      "resolution_mode" => "offline",
      "limitation" => registry.dig("resolution_policy", "offline_behavior")
    }
  end

  def resolve_signals(rules, fixture)
    signals = Array(fixture["signals"]).to_set
    selected = Array(rules["baseline_capabilities"]).to_set
    decisions = []
    Array(rules["rules"]).each do |rule|
      any = Array(rule["signals_any"])
      all = Array(rule["signals_all"])
      matched = (any.empty? || !(signals & any.to_set).empty?) && (all.empty? || all.all? { |s| signals.include?(s) })
      capabilities = Array(rule["capabilities"])
      selected.merge(capabilities) if matched
      decisions << {
        "rule" => rule.fetch("id"),
        "decision" => matched ? "selected" : "excluded",
        "triggering_evidence" => matched ? (signals & (any + all).to_set).to_a.sort : [],
        "reason" => rule.fetch("reason")
      }
    end
    [selected, decisions]
  end

  def dependency_closure(selected, capabilities)
    result = selected.dup
    loop do
      before = result.length
      result.to_a.each { |id| result.merge(Array(capabilities.fetch(id)["dependencies"])) }
      break if before == result.length
    end
    result
  end

  def output_bundle_errors(bundle, location = "output bundle")
    errors = []
    evidence_ids = Array(bundle["evidence_ids"])
    errors << "#{location}: duplicate evidence ids" unless evidence_ids.uniq.length == evidence_ids.length
    finding_ids = Array(bundle["findings"]).map { |finding| finding["id"] }
    errors << "#{location}: duplicate finding ids" unless finding_ids.uniq.length == finding_ids.length
    Array(bundle["findings"]).each do |finding|
      references = Array(finding["evidence_references"]) + Array(finding["closure_evidence"]) + Array(finding["regression_evidence"])
      missing = references - evidence_ids
      errors << "#{location}: #{finding['id']} has unresolved evidence #{missing.join(', ')}" unless missing.empty?
      if finding["status"] == "closed" && (Array(finding["closure_evidence"]).empty? || Array(finding["regression_evidence"]).empty?)
        errors << "#{location}: closed finding #{finding['id']} lacks closure or regression evidence"
      end
    end
    Array(bundle["capabilities"]).each do |capability|
      missing = Array(capability["required_outputs"]) - Array(capability["produced_outputs"])
      errors << "#{location}: #{capability['id']} lacks outputs #{missing.join(', ')}" unless missing.empty?
    end
    required = %w[execution-manifest evidence-register findings-register risk-register summary-report]
    missing = required - Array(bundle["output_inventory"])
    errors << "#{location}: missing execution outputs #{missing.join(', ')}" unless missing.empty?
    errors
  end

  def run
    errors = []
    facts = {}

    yaml_files = Dir[PACKAGE.join("**/*.yaml")].sort.map { |p| Pathname.new(p) }
    json_files = Dir[PACKAGE.join("**/*.json")].sort.map { |p| Pathname.new(p) }
    yaml_files.each { |path| load_yaml(path) }
    json_files.each { |path| JSON.parse(path.read) }
    facts[:yaml_files] = yaml_files.length
    facts[:json_files] = json_files.length

    capability_files = Dir[PACKAGE.join("capabilities/**/*.yaml")].sort.map { |p| Pathname.new(p) }
    capability_schema = load_yaml(PACKAGE.join("standards/capability.schema.yaml"))
    capabilities = {}
    capability_files.each do |path|
      cap = load_yaml(path)
      prefix = path.relative_path_from(ROOT).to_s
      errors.concat(schema_errors(cap, capability_schema, prefix))
      missing = REQUIRED_CAPABILITY_FIELDS - cap.keys
      errors << "#{prefix}: missing fields #{missing.join(', ')}" unless missing.empty?
      id = cap["id"]
      errors << "#{prefix}: invalid capability id #{id.inspect}" unless id.is_a?(String) && id.match?(CAPABILITY_ID)
      errors << "#{prefix}: duplicate capability id #{id}" if capabilities.key?(id)
      capabilities[id] = cap
      errors << "#{prefix}: version must be semantic" unless cap["version"].to_s.match?(SEMVER)
      errors << "#{prefix}: control_objectives must contain at least two objectives" unless Array(cap["control_objectives"]).length >= 2
      objective_ids = Array(cap["control_objectives"]).map { |o| o["id"] if o.is_a?(Hash) }.compact
      errors << "#{prefix}: control objective ids must be unique" unless objective_ids.uniq.length == objective_ids.length
      errors << "#{prefix}: evidence must define required, optional and sufficiency" unless %w[required optional sufficiency].all? { |k| cap.fetch("evidence", {}).key?(k) }
      errors << "#{prefix}: positive and negative test recipes are required" unless %w[positive negative].all? { |k| Array(cap.dig("test_recipes", k)).any? }
      errors << "#{prefix}: dependencies must be an array" unless cap["dependencies"].is_a?(Array)
      errors << "#{prefix}: capability-specific questions are required" unless Array(cap["questions"]).any?
      finding_format = cap.dig("outputs", "finding_format")
      errors << "#{prefix}: unresolved finding format #{finding_format}" unless finding_format && PACKAGE.join(finding_format).file?
    end
    facts[:capability_files] = capability_files.length
    facts[:unique_capability_ids] = capabilities.length
    facts[:unique_objective_sets] = capabilities.values.map { |cap| cap["control_objectives"] }.uniq.length
    facts[:unique_test_recipe_sets] = capabilities.values.map { |cap| cap["test_recipes"] }.uniq.length

    catalogue = load_yaml(PACKAGE.join("catalogue/capabilities.yaml"))
    entries = Array(catalogue["capabilities"])
    entry_ids = entries.map { |entry| entry["id"] }
    errors << "catalogue: count does not match entries" unless catalogue["count"] == entries.length
    errors << "catalogue: duplicate ids" unless entry_ids.uniq.length == entry_ids.length
    errors << "catalogue: ids differ from capability library" unless entry_ids.to_set == capabilities.keys.to_set
    entries.each do |entry|
      path = PACKAGE.join(entry["path"].to_s)
      errors << "catalogue: missing path #{entry['path']}" unless path.file?
      next unless path.file?
      errors << "catalogue: #{entry['id']} path contains #{load_yaml(path)['id']}" unless load_yaml(path)["id"] == entry["id"]
    end

    capabilities.each do |id, cap|
      Array(cap["dependencies"]).each do |dependency|
        errors << "#{id}: missing dependency #{dependency}" unless capabilities.key?(dependency)
      end
    end
    visiting = {}
    visit = lambda do |id, trail|
      if visiting[id] == :active
        errors << "dependency cycle: #{(trail + [id]).join(' -> ')}"
        return
      end
      return if visiting[id] == :done
      visiting[id] = :active
      Array(capabilities.fetch(id)["dependencies"]).each { |dependency| visit.call(dependency, trail + [id]) if capabilities.key?(dependency) }
      visiting[id] = :done
    end
    capabilities.each_key { |id| visit.call(id, []) }

    journeys = Dir[PACKAGE.join("journeys/*.yaml")].sort.map { |p| load_yaml(Pathname.new(p)) }
    journeys.each do |journey|
      Array(journey["stages"]).each do |stage|
        Array(stage[1]).each do |reference|
          next if reference.start_with?("dynamic:", "permission-", "capability-")
          errors << "#{journey['id']}: unresolved capability #{reference}" unless capabilities.key?(reference)
        end
      end
    end

    registry = load_yaml(PACKAGE.join("standards/registry.yaml"))
    standard_ids = Array(registry["standards"]).map { |s| s["id"] }
    registered = standard_ids.to_set
    overlay_ids = Dir[PACKAGE.join("standards/overlays/**/*.yaml")].map { |p| load_yaml(Pathname.new(p))["id"] }.to_set
    standards_documents = yaml_files.reject { |path| path == PACKAGE.join("standards/registry.yaml") }.map do |path|
      [path.relative_path_from(ROOT).to_s, load_yaml(path)]
    end
    errors.concat(standards_integrity_errors(registry, documents: standards_documents, overlay_ids: overlay_ids))
    facts[:standard_references] = standards_documents.sum { |_source, document| framework_references(document).length }

    rules = load_yaml(PACKAGE.join("orchestrator/selection-rules.yaml"))
    Array(rules["baseline_capabilities"]).each { |id| errors << "selection baseline: missing #{id}" unless capabilities.key?(id) }
    Array(rules["rules"]).each do |rule|
      Array(rule["capabilities"]).each { |id| errors << "selection rule #{rule['id']}: missing #{id}" unless capabilities.key?(id) }
    end
    fixture_count = 0
    Dir[ROOT.join("test/fixtures/selection/*.yaml")].sort.each do |path|
      fixture_count += 1
      fixture = load_yaml(Pathname.new(path))
      selected, decisions = resolve_signals(rules, fixture)
      selected = dependency_closure(selected, capabilities)
      expected = Array(fixture["expected_capabilities"]).to_set
      errors << "#{Pathname.new(path).relative_path_from(ROOT)}: selection mismatch; expected #{expected.to_a.sort}, got #{selected.to_a.sort}" unless selected == expected
      errors << "#{path}: every rule must record a decision" unless decisions.length == Array(rules["rules"]).length
    end
    facts[:selection_fixtures] = fixture_count

    assurance_fixture_count = 0
    Dir[ROOT.join("test/fixtures/assurance/*.yaml")].sort.each do |path|
      assurance_fixture_count += 1
      fixture = load_yaml(Pathname.new(path))
      capability = capabilities[fixture["capability"]]
      errors << "#{path}: unknown capability #{fixture['capability']}" unless capability
      next unless capability
      missing_evidence = Array(fixture["expected_required_evidence"]) - Array(capability.dig("evidence", "required"))
      errors << "#{path}: capability does not request #{missing_evidence.join(', ')}" unless missing_evidence.empty?
      errors << "#{path}: invalid expected outcome" unless OUTCOMES.include?(fixture["expected_outcome"])
      if %w[insufficient-evidence not-executed blocked].include?(fixture["expected_outcome"]) && fixture["expected_finding"]
        errors << "#{path}: incomplete evidence must not invent a finding"
      end
    end
    facts[:assurance_fixtures] = assurance_fixture_count

    schema_names = %w[capability finding execution capability-outcome selection-decision output-inventory]
    schema_names.each do |name|
      candidates = [PACKAGE.join("schemas/#{name}.schema.json"), PACKAGE.join("standards/#{name}.schema.yaml")]
      errors << "missing executable schema for #{name}" unless candidates.any?(&:file?)
    end
    %w[finding execution capability-outcome selection-decision output-inventory].each do |name|
      schema = JSON.parse(PACKAGE.join("schemas/#{name}.schema.json").read)
      errors << "#{name} schema must reject unknown properties" unless schema["additionalProperties"] == false
    end
    finding_schema = JSON.parse(PACKAGE.join("schemas/finding.schema.json").read)
    Dir[PACKAGE.join("examples/findings/*.json")].sort.each do |path|
      finding = JSON.parse(File.read(path))
      errors.concat(schema_errors(finding, finding_schema, Pathname.new(path).relative_path_from(ROOT).to_s))
      Array(finding["authoritative_basis"]).each do |basis|
        errors << "#{path}: unresolved authoritative basis #{basis['standard_id']}" unless registered.include?(basis["standard_id"])
      end
    end
    execution_schema = JSON.parse(PACKAGE.join("schemas/execution.schema.json").read)
    execution_template = load_yaml(PACKAGE.join("templates/plans/execution.yaml"))
    errors.concat(schema_errors(execution_template, execution_schema, ".soas/templates/plans/execution.yaml"))
    Dir[ROOT.join("test/fixtures/outputs/*.yaml")].sort.each do |path|
      errors.concat(output_bundle_errors(load_yaml(Pathname.new(path)), Pathname.new(path).relative_path_from(ROOT).to_s))
    end

    expected_headers = {
      "evidence-register.csv" => %w[evidence_id type source location observed_at subject_version collector provenance scope_match freshness independence reproducibility integrity completeness corroboration supports limitations],
      "findings-register.csv" => %w[finding_id title severity confidence priority status capability owner owner_state affected_scope framework_references evidence_references updated_at],
      "risk-register.csv" => %w[risk_id title likelihood impact exposure rating priority owner treatment acceptance_expiry status evidence_references updated_at]
    }
    expected_headers.each do |file, headers|
      actual = CSV.parse_line(PACKAGE.join("templates/registers/#{file}").read.lines.first)
      errors << "#{file}: header contract mismatch" unless actual == headers
    end

    %w[README.md START-HERE.md CONTRIBUTING.md CHANGELOG.md VERSION NOTICE DISCLAIMER.md LICENSE].each do |file|
      errors << "#{file}: root and distributable package copies differ" unless ROOT.join(file).read == PACKAGE.join(file).read
    end

    facts[:journeys] = journeys.length
    facts[:standards] = registered.length
    facts[:outcome_vocabulary] = OUTCOMES
    Result.new(errors: errors, facts: facts)
  rescue StandardError => e
    Result.new(errors: [e.message], facts: facts || {})
  end
end

if $PROGRAM_NAME == __FILE__
  result = SOASValidation.run
  puts JSON.pretty_generate(result.facts)
  if result.success?
    puts "SOAS validation passed"
    exit 0
  end
  warn result.errors.map { |error| "ERROR: #{error}" }.join("\n")
  exit 1
end
