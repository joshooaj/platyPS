using namespace System.Text

Import-LocalizedData -BindingVariable LocalizedData -FileName platyPS.Resources.psd1

$script:EXTERNAL_HELP_FILE_YAML_HEADER = 'external help file'
$script:ONLINE_VERSION_YAML_HEADER = 'online version'
$script:SCHEMA_VERSION_YAML_HEADER = 'schema'
$script:APPLICABLE_YAML_HEADER = 'applicable'

$script:UTF8_NO_BOM = [UTF8Encoding]::new($false)
$script:SET_NAME_PLACEHOLDER = 'UNNAMED_PARAMETER_SET'
# TODO: this is just a place-holder, we can do better
$script:DEFAULT_MAML_XML_OUTPUT_NAME = 'rename-me-help.xml'

$script:MODULE_PAGE_MODULE_NAME = "Module Name"
$script:MODULE_PAGE_GUID = "Module Guid"
$script:MODULE_PAGE_LOCALE = "Locale"
$script:MODULE_PAGE_FW_LINK = "Download Help Link"
$script:MODULE_PAGE_HELP_VERSION = "Help Version"
$script:MODULE_PAGE_ADDITIONAL_LOCALE = "Additional Locale"

$script:MAML_ONLINE_LINK_DEFAULT_MONIKER = 'Online Version:'

#region dot-source private/public functions
# IMPORTANT: This region is replaced during build and the region/endregion tags are required.
foreach ($ps1File in Get-ChildItem -Path "$PSScriptRoot\Private\*.ps1", "$PSScriptRoot\Public\*.ps1" -ErrorAction Stop) {
    try {
        . $ps1File
    } catch {
        throw
    }
}
#endregion

#                                       bbbbbbbb
# TTTTTTTTTTTTTTTTTTTTTTT               b::::::b                                     CCCCCCCCCCCCC                                                             lllllll                              tttt            iiii
# T:::::::::::::::::::::T               b::::::b                                  CCC::::::::::::C                                                             l:::::l                           ttt:::t           i::::i
# T:::::::::::::::::::::T               b::::::b                                CC:::::::::::::::C                                                             l:::::l                           t:::::t            iiii
# T:::::TT:::::::TT:::::T                b:::::b                               C:::::CCCCCCCC::::C                                                             l:::::l                           t:::::t
# TTTTTT  T:::::T  TTTTTTaaaaaaaaaaaaa   b:::::bbbbbbbbb                      C:::::C       CCCCCC   ooooooooooo      mmmmmmm    mmmmmmm   ppppp   ppppppppp    l::::l     eeeeeeeeeeee    ttttttt:::::ttttttt    iiiiiii    ooooooooooo   nnnn  nnnnnnnn
#         T:::::T        a::::::::::::a  b::::::::::::::bb                   C:::::C               oo:::::::::::oo  mm:::::::m  m:::::::mm p::::ppp:::::::::p   l::::l   ee::::::::::::ee  t:::::::::::::::::t    i:::::i  oo:::::::::::oo n:::nn::::::::nn
#         T:::::T        aaaaaaaaa:::::a b::::::::::::::::b                  C:::::C              o:::::::::::::::om::::::::::mm::::::::::mp:::::::::::::::::p  l::::l  e::::::eeeee:::::eet:::::::::::::::::t     i::::i o:::::::::::::::on::::::::::::::nn
#         T:::::T                 a::::a b:::::bbbbb:::::::b --------------- C:::::C              o:::::ooooo:::::om::::::::::::::::::::::mpp::::::ppppp::::::p l::::l e::::::e     e:::::etttttt:::::::tttttt     i::::i o:::::ooooo:::::onn:::::::::::::::n
#         T:::::T          aaaaaaa:::::a b:::::b    b::::::b -:::::::::::::- C:::::C              o::::o     o::::om:::::mmm::::::mmm:::::m p:::::p     p:::::p l::::l e:::::::eeeee::::::e      t:::::t           i::::i o::::o     o::::o  n:::::nnnn:::::n
#         T:::::T        aa::::::::::::a b:::::b     b:::::b --------------- C:::::C              o::::o     o::::om::::m   m::::m   m::::m p:::::p     p:::::p l::::l e:::::::::::::::::e       t:::::t           i::::i o::::o     o::::o  n::::n    n::::n
#         T:::::T       a::::aaaa::::::a b:::::b     b:::::b                 C:::::C              o::::o     o::::om::::m   m::::m   m::::m p:::::p     p:::::p l::::l e::::::eeeeeeeeeee        t:::::t           i::::i o::::o     o::::o  n::::n    n::::n
#         T:::::T      a::::a    a:::::a b:::::b     b:::::b                  C:::::C       CCCCCCo::::o     o::::om::::m   m::::m   m::::m p:::::p    p::::::p l::::l e:::::::e                 t:::::t    tttttt i::::i o::::o     o::::o  n::::n    n::::n
#       TT:::::::TT    a::::a    a:::::a b:::::bbbbbb::::::b                   C:::::CCCCCCCC::::Co:::::ooooo:::::om::::m   m::::m   m::::m p:::::ppppp:::::::pl::::::le::::::::e                t::::::tttt:::::ti::::::io:::::ooooo:::::o  n::::n    n::::n
#       T:::::::::T    a:::::aaaa::::::a b::::::::::::::::b                     CC:::::::::::::::Co:::::::::::::::om::::m   m::::m   m::::m p::::::::::::::::p l::::::l e::::::::eeeeeeee        tt::::::::::::::ti::::::io:::::::::::::::o  n::::n    n::::n
#       T:::::::::T     a::::::::::aa:::ab:::::::::::::::b                        CCC::::::::::::C oo:::::::::::oo m::::m   m::::m   m::::m p::::::::::::::pp  l::::::l  ee:::::::::::::e          tt:::::::::::tti::::::i oo:::::::::::oo   n::::n    n::::n
#       TTTTTTTTTTT      aaaaaaaaaa  aaaabbbbbbbbbbbbbbbb                            CCCCCCCCCCCCC   ooooooooooo   mmmmmm   mmmmmm   mmmmmm p::::::pppppppp    llllllll    eeeeeeeeeeeeee            ttttttttttt  iiiiiiii   ooooooooooo     nnnnnn    nnnnnn
#                                                                                                                                           p:::::p
#                                                                                                                                           p:::::p
#                                                                                                                                          p:::::::p
#                                                                                                                                          p:::::::p
#                                                                                                                                          p:::::::p
#                                                                                                                                          ppppppppp

if (Get-Command -Name Microsoft.PowerShell.Core\Register-ArgumentCompleter -ErrorAction Ignore) {
    Microsoft.PowerShell.Core\Register-ArgumentCompleter -CommandName New-MarkdownHelp -ParameterName Module -ScriptBlock $Function:ModuleNameCompleter
}