<?php
	if (empty ($argv[1]))
	{
		printf ('ERROR: Project name is not set!');
		return false;
	}

	$project_name = $argv[1];
	$directory = realpath ('.\\..\\' . $project_name .'\\bin\\i18n');
	$example_file = $directory . '\\!example.txt';
	$lng_path = $directory . '\\..\\'. $project_name .'.lng';
	$lng_header = '; ' . $project_name . PHP_EOL . PHP_EOL;

	if (!file_exists ($example_file))
	{
		printf ('ERROR: "%s" not found in "%s" directory' . PHP_EOL, pathinfo ($example_file, PATHINFO_BASENAME), $directory);
		return false;
	}

	$cfg_force_default = [
	];

	$cfg_force_delete = [
	];

	$cfg_force_rename = [
	];

	$original_content = conv (file_get_contents ($example_file), false);
	$original_array = parse_ini_string ($original_content, false, INI_SCANNER_RAW);

	$ini_array = glob ($directory .'\\*.ini');

	$buffer_total = $lng_header;

	foreach ($ini_array as $ini_file)
	{
		$locale_name = pathinfo ($ini_file, PATHINFO_FILENAME);

		printf ('Processing "%s" locale...' . PHP_EOL, $ini_file);

		$new_content = conv (file_get_contents ($ini_file), false);
		$new_array = parse_ini_string ($new_content, false, INI_SCANNER_RAW);

		$buffer = sprintf ('[%s]' . PHP_EOL, $locale_name);

		if (!array_key_exists ('IDS_AUTHOR', $new_array))
		{
			// init header
			$file_header = strstr ($new_content, PHP_EOL . PHP_EOL, true);

			if (!empty ($file_header))
			{
				$arr = explode (PHP_EOL, $file_header);

				if (count ($arr) >= 2)
					$new_array['IDS_AUTHOR'] = trim($arr[1], "\r\n; ");
			}
		}

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

			$buffer .= sprintf ('%s=%s' . PHP_EOL, $key, $text);
		}

		unset ($key, $val);

		file_put_contents ($ini_file, conv ($buffer, true));
		$buffer_total .= $buffer . PHP_EOL;
	}

	file_put_contents ($lng_path, conv ($buffer_total, true));

	function conv ($text, $to_utf16)
	{
		$result = mb_convert_encoding ($text, $to_utf16 ? 'UTF-16LE' : 'UTF-8', $to_utf16 ? 'UTF-8' : 'UTF-16LE');

		return $to_utf16 ? "\xFF\xFE" . $result : $result;
	}
?>
