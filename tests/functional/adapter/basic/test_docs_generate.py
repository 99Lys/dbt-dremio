# Copyright (C) 2022 Dremio Corporation

# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at

# http://www.apache.org/licenses/LICENSE-2.0

# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

import pytest
import os
from tests.utils.util import (
    base_expected_catalog,
    expected_references_catalog,
    BUCKET,
)
from dbt.tests.adapter.basic.test_docs_generate import (
    BaseDocsGenerate,
    BaseDocsGenReferences,
    verify_metadata,
    run_and_generate,
    get_artifact,
    ref_models__schema_yml,
    ref_models__view_summary_sql,
    ref_models__ephemeral_summary_sql,
    ref_models__ephemeral_copy_sql,
    ref_models__docs_md,
)
from dbt.tests.adapter.basic.expected_catalog import no_stats


ref_sources__schema_yml = """
version: 2
sources:
  - name: my_source
    description: "{{ doc('source_info') }}"
    loader: a_loader
    database: "{{ target.datalake }}"
    schema: "{{ var('test_schema') }}"
    tables:
      - name: my_table
        description: "{{ doc('table_info') }}"
        identifier: seed
        columns:
          - name: id
            description: "{{ doc('column_info') }}"
"""

# Remove check for sources and only include nodes
def verify_catalog_nodes(project, expected_catalog, start_time):
    # get the catalog.json
    catalog_path = os.path.join(project.project_root, "target", "catalog.json")
    assert os.path.exists(catalog_path)
    catalog = get_artifact(catalog_path)
    # verify the catalog
    assert set(catalog) == {"errors", "metadata", "nodes", "sources"}
    verify_metadata(
        catalog["metadata"],
        "https://schemas.getdbt.com/dbt/catalog/v1.json",
        start_time,
    )
    assert not catalog["errors"]
    key = "nodes"
    for unique_id, expected_node in expected_catalog[key].items():
        found_node = catalog[key][unique_id]
        for node_key in expected_node:
            assert node_key in found_node
            assert (
                found_node[node_key] == expected_node[node_key]
            ), f"Key '{node_key}' in '{unique_id}' did not match"


class TestBaseDocsGenerateDremio(BaseDocsGenerate):
    @pytest.fixture(scope="class")
    def unique_schema(self, request, prefix) -> str:
        test_file = request.module.__name__
        test_file = test_file.split(".")[-1]
        unique_schema = f"{BUCKET}.{prefix}_{test_file}"
        return unique_schema

    # Override this fixture to set root_path=schema
    @pytest.fixture(scope="class")
    def dbt_profile_data(
        self, unique_schema, dbt_profile_target, profiles_config_update
    ):
        profile = {
            "test": {
                "outputs": {
                    "default": {},
                },
                "target": "default",
            },
        }
        target = dbt_profile_target
        target["schema"] = unique_schema
        target["root_path"] = unique_schema
        profile["test"]["outputs"]["default"] = target
        if profiles_config_update:
            profile.update(profiles_config_update)
        return profile

    # Override this fixture to change expected types to Dremio types
    @pytest.fixture(scope="class")
    def expected_catalog(self, project):
        return base_expected_catalog(
            project,
            role=None,
            id_type="bigint",
            text_type="character varying",
            time_type="timestamp",
            view_type="view",
            table_type="table",
            model_stats=no_stats(),
        )

    # Test "--no-compile" flag works and produces no manifest.json
    def test_run_and_generate_no_compile(self, project, expected_catalog):
        start_time = run_and_generate(project, ["--no-compile"])
        assert not os.path.exists(
            os.path.join(project.project_root, "target", "manifest.json")
        )
        verify_catalog_nodes(project, expected_catalog, start_time)

    # Test generic "docs generate" command
    def test_run_and_generate(self, project, expected_catalog):
        start_time = run_and_generate(project)
        verify_catalog_nodes(project, expected_catalog, start_time)

        # Check that assets have been copied to the target directory for use in the docs html page
        assert os.path.exists(os.path.join(".", "target", "assets"))
        assert os.path.exists(os.path.join(".", "target", "assets", "lorem-ipsum.txt"))
        assert not os.path.exists(os.path.join(".", "target", "non-existent-assets"))


class TestBaseDocsGenReferencesDremio(BaseDocsGenReferences):
    @pytest.fixture(scope="class")
    def models(self):
        return {
            "schema.yml": ref_models__schema_yml,
            "sources.yml": ref_sources__schema_yml,
            "view_summary.sql": ref_models__view_summary_sql,
            "ephemeral_summary.sql": ref_models__ephemeral_summary_sql,
            "ephemeral_copy.sql": ref_models__ephemeral_copy_sql,
            "docs.md": ref_models__docs_md,
        }

    @pytest.fixture(scope="class")
    def unique_schema(self, request, prefix) -> str:
        test_file = request.module.__name__
        test_file = test_file.split(".")[-1]
        unique_schema = f"{BUCKET}.{prefix}_{test_file}"
        return unique_schema

    # Override this fixture to set root_path=schema
    @pytest.fixture(scope="class")
    def dbt_profile_data(
        self, unique_schema, dbt_profile_target, profiles_config_update
    ):
        profile = {
            "test": {
                "outputs": {
                    "default": {},
                },
                "target": "default",
            },
        }
        target = dbt_profile_target
        target["schema"] = unique_schema
        target["root_path"] = unique_schema
        profile["test"]["outputs"]["default"] = target

        if profiles_config_update:
            profile.update(profiles_config_update)
        return profile

    # Override this fixture to change expected types to Dremio types
    @pytest.fixture(scope="class")
    def expected_catalog(self, project):
        return expected_references_catalog(
            project,
            role=None,
            id_type="bigint",
            text_type="character varying",
            time_type="timestamp",
            view_type="view",
            table_type="table",
            model_stats=no_stats(),
            bigint_type="bigint",
        )

    def test_references(self, project, expected_catalog):
        start_time = run_and_generate(project)
        verify_catalog_nodes(project, expected_catalog, start_time)
