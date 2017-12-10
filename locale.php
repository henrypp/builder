<?php
	if (empty ($argv[1]))
	{
		printf ('ERROR: Project name is not set!');
		return false;
	}

	$eol = "\r\n";

	$project_name = $argv[1];
	$directory = realpath ('.\\..\\' . $project_name .'\\bin\\i18n');
	$example_file = $directory . '\\!example.txt';
	$lng_path = $directory . '\\..\\'. $project_name .'.lng';
	$lng_header = sprintf ("; Project name: %s" . $eol . "; Last-Modified: %s" . $eol . $eol, $project_name, date ('r', time ()));

	if (!file_exists ($example_file))
	{
		printf ('ERROR: "%s" not found in "%s" directory' . $eol, pathinfo ($example_file, PATHINFO_BASENAME), $directory);
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

	$hfile = fopen ($lng_path, 'wb');
	$buffer_total = $lng_header;

	if ($hfile)
		fwrite ($hfile, $lng_header);

	foreach ($ini_array as $ini_file)
	{
		$locale_name = pathinfo ($ini_file, PATHINFO_FILENAME);

		printf ('Processing "%s" locale...' . $eol, $ini_file);

		$new_content = conv (file_get_contents ($ini_file), false);
		$new_array = parse_ini_string ($new_content, false, INI_SCANNER_RAW);

		$buffer = sprintf ('[%s]' . $eol, $locale_name);

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

			$buffer .= sprintf ('%s=%s' . $eol, $key, $text);
		}

		unset ($key, $val);

		$buffer_total .= $buffer . $eol;
		file_put_contents ($ini_file, conv ($buffer, true));
	}

	if ($hfile)
		fwrite ($hfile, conv ($buffer_total, true));

	if ($hfile)
		fclose ($hfile);

	function conv ($text, $to_utf16) { return mb_convert_encoding ($text, $to_utf16 ? 'UTF-16LE' : 'UTF-8', $to_utf16 ? 'UTF-8' : 'UTF-16LE'); }
?>
