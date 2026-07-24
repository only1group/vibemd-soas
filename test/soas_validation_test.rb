# frozen_string_literal: true

require "minitest/autorun"
require "set"
require_relative "../tools/validate_soas"

class SOASValidationTest < Minitest::Test
  def test_complete_repository_contracts
    result = SOASValidation.run
    assert result.success?, result.errors.join("\n")
    assert_equal 72, result.facts[:capability_files]
    assert_equal 72, result.facts[:unique_capability_ids]
    assert_equal 72, result.facts[:unique_objective_sets]
    assert_equal 72, result.facts[:unique_test_recipe_sets]
    assert_operator result.facts[:selection_fixtures], :>=, 8
    assert_operator result.facts[:assurance_fixtures], :>=, 9
  end

  def test_insufficient_evidence_is_not_a_positive_outcome
    refute_includes %w[satisfied finding-raised], "insufficient-evidence"
    assert_includes SOASValidation::OUTCOMES, "insufficient-evidence"
  end

  def test_closed_finding_without_closure_evidence_is_invalid
    schema = JSON.parse(SOASValidation::PACKAGE.join("schemas/finding.schema.json").read)
    finding = JSON.parse(SOASValidation::PACKAGE.join("examples/findings/closed.json").read)
    finding["verification"].delete("regression_evidence")
    refute_empty SOASValidation.schema_errors(finding, schema)
  end

  def test_output_cross_reference_failures_are_detected
    bundle = SOASValidation.load_yaml(SOASValidation::ROOT.join("test/fixtures/outputs/consistent-bundle.yaml"))
    bundle["evidence_ids"].delete("E-1004-regression")
    refute_empty SOASValidation.output_bundle_errors(bundle)
  end

  def test_finalized_execution_requires_complete_output_inventory
    schema = JSON.parse(SOASValidation::PACKAGE.join("schemas/execution.schema.json").read)
    execution = SOASValidation.load_yaml(SOASValidation::PACKAGE.join("templates/plans/execution.yaml"))
    execution["state"] = "finalized"
    execution["completed_at"] = "2026-07-23T01:00:00Z"
    execution["outcome"] = "satisfied"
    execution["outputs"] = {"summary_report" => "summary.md"}
    refute_empty SOASValidation.schema_errors(execution, schema)
  end

  def test_unknown_standard_reference_fails_with_source_and_location
    registry = SOASValidation.load_yaml(SOASValidation::PACKAGE.join("standards/registry.yaml"))
    documents = [["fixture.yaml", {"frameworks" => {"normative" => ["UNKNOWN-STANDARD"]}}]]
    errors = SOASValidation.standards_integrity_errors(registry, documents: documents, overlay_ids: Set.new)
    assert_includes errors, "fixture.yaml: unresolved standard UNKNOWN-STANDARD at $.frameworks.normative[0]"
  end

  def test_duplicate_standard_id_fails
    registry = SOASValidation.load_yaml(SOASValidation::PACKAGE.join("standards/registry.yaml"))
    registry["standards"] << registry["standards"].first.dup
    errors = SOASValidation.standards_integrity_errors(registry, documents: [], overlay_ids: Set.new)
    assert_includes errors, "standards registry: duplicate ids"
  end

  def test_malformed_standard_entry_fails
    registry = SOASValidation.load_yaml(SOASValidation::PACKAGE.join("standards/registry.yaml"))
    registry["standards"].first.delete("official_source")
    errors = SOASValidation.standards_integrity_errors(registry, documents: [], overlay_ids: Set.new)
    assert_includes errors, "standards registry ISO-25010: missing official_source"
  end

  def test_registered_jurisdiction_overlay_is_not_treated_as_an_unknown_standard
    registry = SOASValidation.load_yaml(SOASValidation::PACKAGE.join("standards/registry.yaml"))
    documents = [["fixture.yaml", {"frameworks" => {"conditional" => ["JUR-AU"]}}]]
    errors = SOASValidation.standards_integrity_errors(registry, documents: documents, overlay_ids: Set["JUR-AU"])
    assert_empty errors
  end

  def test_offline_resolution_uses_pinned_finals
    registry = SOASValidation.load_yaml(SOASValidation::PACKAGE.join("standards/registry.yaml"))
    expected = {
      "ISO-22301" => "2019+Amd 1:2024",
      "ISO-31000" => "2018",
      "ISO-9241-11" => "2018",
      "ISO-9241-110" => "2020",
      "ISO-9241-112" => "2025",
      "ISO-9241-171" => "2025",
      "ISO-9241-210" => "2019"
    }
    expected.each do |identifier, version|
      resolved = SOASValidation.resolve_standard_offline(registry, identifier)
      assert_equal version, resolved["pinned_version"]
      assert_equal "offline", resolved["resolution_mode"]
      refute_empty resolved["limitation"]
    end
  end

  def test_offline_resolution_fails_closed_for_unknown_and_duplicate_ids
    registry = SOASValidation.load_yaml(SOASValidation::PACKAGE.join("standards/registry.yaml"))
    assert_raises(RuntimeError) { SOASValidation.resolve_standard_offline(registry, "UNKNOWN-STANDARD") }
    registry["standards"] << registry["standards"].first.dup
    assert_raises(RuntimeError) { SOASValidation.resolve_standard_offline(registry, registry["standards"].first["id"]) }
  end

  def test_draft_advisory_does_not_displace_pinned_final
    registry = SOASValidation.load_yaml(SOASValidation::PACKAGE.join("standards/registry.yaml"))
    standard = registry["standards"].find { |entry| entry["id"] == "ISO-22301" }
    assert_includes standard["known_advisory"], "under development"
    assert_equal "2019+Amd 1:2024", SOASValidation.resolve_standard_offline(registry, "ISO-22301")["pinned_version"]
  end
end
