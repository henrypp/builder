<?php
	if (empty ($argv[1]) || empty ($argv[2]) || empty ($argv[3]) || empty ($argv[4]) || empty ($argv[5]) || empty ($argv[6]))
		die ('Example usage:' . PHP_EOL . $argv[0] . ' <PROJECT NAME> <PROJECT NAME SHORT> <I18N DIRECTORY> <INPUT RESOURCE.H FILE> <INPUT RESOURCE.RC FILE> <OUTPUT .LNG FILE>' . PHP_EOL);

	$project_name = $argv[1];
	$project_name_short = $argv[2];
	$i18n_directory = $argv[3];
	$example_file = $i18n_directory . '\\!example.txt';
	$resource_h_file = $argv[4];
	$resource_rc_file = $argv[5];
	$lng_file = $argv[6];
	$timestamp_last = 0;

	$resource_id_array = [];
	$resource_rc_array = [];
	$example_content = '; <language name>'. PHP_EOL .'; <author information>'. PHP_EOL . PHP_EOL .'[<locale name here>]' . PHP_EOL;

	if (!file_exists ($i18n_directory) || !file_exists ($example_file) || !file_exists ($resource_h_file) || !file_exists ($resource_rc_file))
		die ('ERROR: Some files are unavailable!' . PHP_EOL);

	$lng_buffer = '; ' . $project_name . PHP_EOL . '; https://github.com/henrypp/' . $project_name_short .'/tree/master/bin/i18n'. PHP_EOL .';'. PHP_EOL . '; DO NOT MODIFY THIS FILE -- YOUR CHANGES WILL BE ERASED!'. PHP_EOL . PHP_EOL;

	function sort_resource ($a, $b)
	{
		if ($GLOBALS['resource_id_array'][$a] == $GLOBALS['resource_id_array'][$b])
			return 0;

		return ($GLOBALS['resource_id_array'][$a] < $GLOBALS['resource_id_array'][$b]) ? -1 : 1;
	}

	function conv ($text, $to_utf16)
	{
		return mb_convert_encoding ($text, $to_utf16 ? 'UTF-16LE' : 'UTF-8', $to_utf16 ? 'UTF-8' : 'UTF-16LE');
	}

	function find_proper_key_name ($numeric_key)
	{
		foreach ($GLOBALS['resource_id_array'] as $key => $val)
		{
			if ($val == $numeric_key)
				return $key;
		}

		unset ($key, $val);

		return NULL;
	}

	// parse resource.h id
	{
		$resource_content = file_get_contents ($resource_h_file);

		if (empty ($resource_content))
			die ('ERROR: Unable to read file '.  $resource_h_file . PHP_EOL);

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
			die ('ERROR: Unable to read file '.  $resource_h_file . PHP_EOL);
	}

	// parse and sort resource.rc
	{
		$resource_content = file_get_contents ($resource_rc_file);

		if (empty ($resource_content))
			die ('ERROR: Unable to read file '.  $resource_rc_file . PHP_EOL);

		$resource_explode_array = explode (PHP_EOL, $resource_content);

		foreach ($resource_explode_array as $val)
		{
			$val = trim ($val, "\t ");

			if (empty ($val) || strncasecmp ($val, 'IDS_', 4) != 0)
				continue;

			$pos = mb_strpos ($val, ' ');

			if ($pos !== FALSE)
			{
				$rc_key = mb_substr ($val, 0, $pos);
				
				if (!array_key_exists ($rc_key, $resource_id_array))
					continue;

				$rc_val = mb_substr ($val, $pos + 1);

				$rc_val = str_replace ('""', '"', trim ($rc_val, '"'));

				$resource_rc_array[$rc_key] = str_replace ('""', '"', trim ($rc_val, '"'));
			}
		}

		unset ($val);

		if (empty ($resource_rc_array))
			die ('ERROR: Unable to read file '.  $resource_h_file . PHP_EOL);
	}

	uksort ($resource_rc_array, 'sort_resource');

	// update "!example.txt" file
	foreach ($resource_rc_array as $key => $val)
	{
		$example_content .= sprintf ('%s=%s' . PHP_EOL, $key, $val);
	}

	unset ($key, $val);

	file_put_contents ($example_file, "\xFF\xFE" . conv ($example_content, true));

	// process every *.ini file
	$ini_array = glob ($i18n_directory .'\\*.ini');

	foreach ($ini_array as $ini_file)
	{
		$timestamp = filemtime ($ini_file);
		$locale_name = pathinfo ($ini_file, PATHINFO_FILENAME);

		if ($timestamp > $timestamp_last)
			$timestamp_last = $timestamp;

		printf ('Processing "%s" locale...' . PHP_EOL, $ini_file);

		$new_content = conv (file_get_contents ($ini_file), false);
		$new_array = parse_ini_string ($new_content, false, INI_SCANNER_RAW);

		if (empty ($new_array))
		{
			print ('ERROR: Unable to read file '.  $ini_file . PHP_EOL);
			continue;
		}

		$buffer = '';
		$ini_header = mb_stristr ($new_content, PHP_EOL . PHP_EOL, true);

		if ($ini_header !== FALSE)
			$buffer .= mb_stristr ($ini_header, ';', false) . PHP_EOL . PHP_EOL;

		$buffer .= sprintf ('[%s]' . PHP_EOL , $locale_name);
		$lng_buffer .= $buffer;
		$lng_buffer .= sprintf ('000=%s' . PHP_EOL, $timestamp);

		// find proper key names
		{
			$another_new_array = [];

			foreach ($new_array as $key => $val)
			{
				if (is_numeric ($key) || ctype_digit ($key))
				{
					$new_key = find_proper_key_name ($key);

					if ($new_key)
					{
						$another_new_array[$new_key] = $val;
						continue;
					}
				}

				$another_new_array[$key] = $val;
			}

			if (!empty($another_new_array))
				$new_array = $another_new_array;

			unset ($key, $val);
		}

		foreach ($resource_rc_array as $key => $val)
		{
			$text = $val;

			if (!empty ($new_array[$key]))
				$text = $new_array[$key];

			$buffer .= sprintf ('%s=%s' . PHP_EOL, $key, $text);

			// write only localized string!
			if (strcmp ($val, $text) != 0)
				$lng_buffer .= sprintf ('%03s=%s' . PHP_EOL, $resource_id_array[$key], $text);
		}

		unset ($key, $val);

		file_put_contents ($ini_file, "\xFF\xFE" . conv ($buffer, true));
		touch ($ini_file, $timestamp, $timestamp);

		$lng_buffer .= PHP_EOL;
	}

	$lng_buffer = rtrim ($lng_buffer, PHP_EOL) . PHP_EOL;

	// write .lng file
	chmod ($lng_file, '0755');
	file_put_contents ($lng_file, "\xFF\xFE" . conv ($lng_buffer, true));
	chmod ($lng_file, '0600');

	print (PHP_EOL . $timestamp_last . PHP_EOL . PHP_EOL);
?>
