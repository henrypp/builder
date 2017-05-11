<?php
	$directory = realpath ('.');
	$example_file = '!example.txt';
	$full_path = $directory . '/' . $example_file;
	$main_section = 'i18n';

	if (!file_exists($full_path))
	{
		printf ('ERROR: "%s" not found in "%s" directory' . PHP_EOL, $example_file, $directory);
		return FALSE;
	}

	$cfg_force_default = [
	];

	$cfg_force_delete = [
	];

	$original_content = mb_convert_encoding (file_get_contents ($full_path), 'UTF-8', 'UTF-16LE');
	$original_array = parse_ini_string ($original_content, FALSE, INI_SCANNER_RAW);

	$files = glob($directory .'\\*.ini');

	foreach ($files as $file) {
		$filename = pathinfo ($file, PATHINFO_BASENAME);

		printf ('Processing file "%s"...' . PHP_EOL, $filename);

		$new_content = mb_convert_encoding (file_get_contents ($file), 'UTF-8', 'UTF-16LE');
		$new_array = parse_ini_string ($new_content, FALSE, INI_SCANNER_RAW);

		// init header
		$new_header = strstr ($new_content, PHP_EOL . PHP_EOL, TRUE);

		if (empty ($new_header))
			$new_header = '; <language name> ' . PHP_EOL . '; <author information>'; // default header

		$buffer = sprintf ('%s' . PHP_EOL . PHP_EOL .  '[%s]' . PHP_EOL, $new_header, $main_section);

		foreach ($original_array as $key => $val) {

			// skip keys marked for deletion
			if (in_array ($key, $cfg_force_delete))
				continue;

			$line = $val;

			if (!empty ($new_array[$key]))
			{
				// reset only predefined keys or "russian" locale ;)
				if (!in_array ($key, $cfg_force_default) || strcasecmp ($filename, 'russian.ini') == 0)
					$line = $new_array[$key];
			}

			$buffer .= sprintf ('%s=%s' . PHP_EOL, $key, $line);
		}

		unset ($key, $val);

		file_put_contents ($file, mb_convert_encoding ($buffer, 'UTF-16LE', 'UTF-8'));
	}

?>
