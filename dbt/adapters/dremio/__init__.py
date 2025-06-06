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

from dbt.adapters.dremio.column import DremioColumn
from dbt.adapters.dremio.connections import DremioConnectionManager
from dbt.adapters.dremio.credentials import DremioCredentials
from dbt.adapters.dremio.impl import DremioAdapter
from dbt.adapters.dremio.column import DremioColumn
from dbt.adapters.base import AdapterPlugin
from dbt.include import dremio


Plugin = AdapterPlugin(
    adapter=DremioAdapter,
    credentials=DremioCredentials,
    include_path=dremio.PACKAGE_PATH,
)
