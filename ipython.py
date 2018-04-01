# Copyright 2017 Google Inc. All rights reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#  http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
"""IPython configuration for Colab."""

c = get_config()  # pylint:disable=undefined-variable

# Register a custom kernel_class.
c.IPKernelApp.kernel_class = 'google.colab._kernel.Kernel'

# Implicitly imported packages.
c.InteractiveShellApp.extensions = [
    'matplotlib',
    'seaborn',
]

# Startup code.
c.InteractiveShellApp.exec_lines = [
    'from google.colab import _shell_customizations',
    '_shell_customizations.initialize()',
    # TODO(b/72409705): Remove this extra import.
    'import h5py',
]

# Enable matplotlib renderings to show up inline in the notebook.
c.InteractiveShellApp.matplotlib = 'inline'
