function GetSchemaVersion
{
    param(
        [string]$markdown
    )

    $metadata = Get-MarkdownMetadata -markdown $markdown
    if ($metadata)
    {
        $schema = $metadata[$script:SCHEMA_VERSION_YAML_HEADER]
    }

    if (-not $schema)
    {
        # either there is no metadata, or schema version is not specified.
        # assume 2.0.0
        $schema = '2.0.0'
    }

    return $schema
}