<?php
	if (empty($argv[1]))
	{
		die ('Example usage:' . PHP_EOL . $argv[0] . ' <INFILE> <OUTFILE>' . PHP_EOL);
	}

	$resource_in_path = $argv[1];
	
	if (!empty($argv[2]))
		$resource_out_path = $argv[2];
	else
		$resource_out_path = $resource_in_path;

	$resource_buffer = NULL;

	$uint_dialog = 100;
	$uint_icon = 100;
	$uint_control = 100;
	$uint_ptr = 100;
	$uint_string = 1;
	$uint_rcdata = 1;
	$uint_accelerator = 1;

	$resource_content = file_get_contents ($resource_in_path);

	if (empty ($resource_content))
		die ('ERROR: Unable to read file '. $resource_in_path . PHP_EOL);

	$resource_explode = explode (PHP_EOL, $resource_content);

	if (empty ($resource_explode))
		die ('ERROR: Unable to read file '. $resource_in_path . PHP_EOL);

	foreach ($resource_explode as $val)
	{
		if (strncasecmp ($val, '#define ', 7) == 0)
		{
			$arr = explode (' ', $val);

			if (!empty ($arr[1]) && !empty ($arr[2]) && is_numeric ($arr[2]))
			{
				$name = $arr[1];
				$id = $arr[2];

				if (strncasecmp ($name, 'IDC_', 4) == 0 || strncasecmp ($name, 'IDM_', 4) == 0)
					$id = $uint_control++;
				
				else if (strncasecmp ($name, 'IDS_', 4) == 0)
					$id = $uint_string++;

				else if (strncasecmp ($name, 'IDI_', 4) == 0)
					$id = $uint_icon++;

				else if (strncasecmp ($name, 'IDD_', 4) == 0)
					$id = $uint_dialog++;

				else if (strncasecmp ($name, 'IDR_', 4) == 0)
					$id = $uint_rcdata++;

				else if (strncasecmp ($name, 'IDA_', 4) == 0)
					$id = $uint_accelerator++;

				else if (strncasecmp ($name, 'IDP_', 4) == 0)
					$id = $uint_ptr++;

				$resource_buffer .= sprintf ('#define %s %s' . PHP_EOL, $name, $id);
			}
			else
			{
				$resource_buffer .= $val . PHP_EOL;
			}
		}
		else
		{
			$resource_buffer .= $val . PHP_EOL;
		}
	}

	file_put_contents ($resource_out_path, trim ($resource_buffer, PHP_EOL). PHP_EOL);
?>
