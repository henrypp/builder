<?php
	if (empty($argv[1]) || empty($argv[2]) || empty($argv[3]) || empty($argv[4]) || empty($argv[5]))
	{
		die ('Example usage:' . PHP_EOL . $argv[0] . ' <PROJECT NAME> <PROJECT NAME SHORT> <I18N DIRECTORY> <INPUT RESOURCE.H FILE> <OUTPUT .LNG FILE>' . PHP_EOL);
	}

	$project_name = $argv[1];
	$project_name_short = $argv[2];
	$i18n_directory = $argv[3];
	$example_file = $i18n_directory . '\\!example.txt';
	$resource_file = $argv[4];
	$lng_file = $argv[5];

	if (!file_exists ($i18n_directory) || !file_exists ($example_file) || !file_exists ($resource_file))
	{
		die ('Some files are unavailable!' . PHP_EOL);
	}

	$lng_header = '; ' . $project_name . PHP_EOL . '; https://github.com/henrypp/' . $project_name_short .'/tree/master/bin/i18n'. PHP_EOL .';'. PHP_EOL . '; DO NOT MODIFY THIS FILE -- YOUR CHANGES WILL BE ERASED!'. PHP_EOL . PHP_EOL;

	$cfg_force_default = [
	];

	$cfg_force_delete = [
	];

	$cfg_force_rename = [
	];

	{
		$resource_content = file_get_contents ($resource_file);
		$resource_id_array = [];

		if (empty ($resource_content))
			die ('ERROR: Unable to read file '.  $resource_file . PHP_EOL);

		$resource_explode_array = explode (PHP_EOL, $resource_content);

		foreach ($resource_explode_array as $val)
		{
			if (empty ($val) || strncasecmp ($val, '#define IDS_', 12) != 0)
				continue;

			$arr = explode (' ', $val);

			if (!empty ($arr[1]))
				$resource_id_array[$arr[1]] = $arr[2];
		}

		if (empty ($resource_id_array))
			die ('ERROR: Unable to read file '.  $resource_file . PHP_EOL);
	}

	$original_content = conv (file_get_contents ($example_file), false);
	$original_array = parse_ini_string ($original_content, false, INI_SCANNER_RAW);

	$ini_array = glob ($i18n_directory .'\\*.ini');

	$lng_buffer = $lng_header;

	foreach ($ini_array as $ini_file)
	{
		$locale_name = pathinfo ($ini_file, PATHINFO_FILENAME);

		printf ('Processing "%s" locale...' . PHP_EOL, $ini_file);

		$new_content = conv (file_get_contents ($ini_file), false);
		$new_array = parse_ini_string ($new_content, false, INI_SCANNER_RAW);

		$buffer = NULL;
		$ini_header = stristr ($new_content, PHP_EOL . PHP_EOL, true);

		if ($ini_header !== FALSE)
			$buffer .= $ini_header . PHP_EOL . PHP_EOL;

		$buffer .= sprintf ('[%s]' . PHP_EOL, $locale_name);
		$lng_buffer .= $buffer;

		foreach ($original_array as $key => $val)
		{
			// skip keys marked for deletion
			if (in_array ($key, $cfg_force_delete))
				continue;

			$text = $val;

			if (array_key_exists ($key, $cfg_force_rename))
			{
				// rename key
				if(!empty ($new_array[$cfg_force_rename[$key]]))
					$text = $new_array[$cfg_force_rename[$key]];

				else if (!empty ($new_array[$key]))
					$text = $new_array[$key];

				$key = $cfg_force_rename[$key];
			}
			else if (!empty ($new_array[$key]))
			{
				// reset only predefined keys or "russian" locale ;)
				if (!in_array ($key, $cfg_force_default) || strcasecmp ($filename, 'russian') == 0)
					$text = $new_array[$key];
			}

			if (!array_key_exists ($key, $resource_id_array))
				continue;

			$buffer .= sprintf ('%s=%s' . PHP_EOL, $key, $text);
			$lng_buffer .= sprintf ('%03s=%s' . PHP_EOL, $resource_id_array[$key], $text);
		}

		unset ($key, $val);

		file_put_contents ($ini_file, conv ($buffer, true));
		$lng_buffer .= PHP_EOL;
	}

	$lng_buffer = rtrim ($lng_buffer, PHP_EOL) . PHP_EOL;
	
	file_put_contents ($lng_file, conv ($lng_buffer, true));

	function conv ($text, $to_utf16)
	{
		$result = mb_convert_encoding ($text, $to_utf16 ? 'UTF-16LE' : 'UTF-8', $to_utf16 ? 'UTF-8' : 'UTF-16LE');

		return $to_utf16 ? "\xFF\xFE" . $result : $result;
	}
?>
