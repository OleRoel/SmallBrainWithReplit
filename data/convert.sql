COPY (
    SELECT
        label,
        list_transform(
            string_split(pixels, ',')::INTEGER[],
            lambda x : (x::FLOAT / 252.45) + 0.01
        ) AS pixels
    FROM read_csv('${input}',
        delim = '|',
        header = true,
        columns = {
            'label': 'INT',
            'pixels': 'VARCHAR'
        })
) TO '${output}';
