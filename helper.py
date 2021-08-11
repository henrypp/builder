import glob
import hashlib
import logging
import os
import time
import platform
import shutil

class status:
	TITLE  = 'xx'
	FAILED  = '\033[31m' # red
	SUCCESS  = '\033[32m' # green
	WARNING  = '\033[33m' # orange
	BLUE  = '\033[34m' # blue
	PURPLE  = '\033[35m' # purple
	WHITE  = '\033[0m'  # white (normal)

def is_os_64bit ():
	return platform.machine ().endswith ('64')

def clr_to_console (clr):
	if clr == status.TITLE:
		return '\n'

	elif clr == status.FAILED:
		return status.FAILED + '[failed]' + status.WHITE + '  - '

	elif clr == status.SUCCESS:
		return status.SUCCESS + '[success]' + status.WHITE + ' - '

	elif clr == status.WARNING:
		return status.WARNING + '[warning]' + status.WHITE + ' - '

	return '[debug]   - '

def log_status (clr, text):
	if clr == status.TITLE:
		text += ':'

	print (clr_to_console (clr) + text)

def check_path_with_status (title, path, is_file=False):
	is_exists = False

	if is_file:
		is_exists = os.path.isfile (path)
	else:
		is_exists = os.path.isdir (path)

	if is_exists:
		log_status (status.SUCCESS, title + ' "' + get_file_name (path) + '" was found')
	else:
		log_status (status.FAILED, title + ' "' + get_file_name (path) + '" was not found')
		os.sys.exit ('')

def get_file_name (path):
	dir_name = os.path.basename (os.path.dirname (path))

	dir_name = os.path.basename (os.path.dirname (path))

	if not dir_name:
		dir_name = os.path.basename (path)

	if not dir_name:
		return path

	dir_sub_name = os.path.join (dir_name, os.path.basename (path))

	if not dir_sub_name:
		dir_sub_name = os.path.basename (path)

	return dir_sub_name

def get_sha256 (path):
	with open (path, 'rb') as fn:
		buff = fn.read ()
		fn.close ()

		return hashlib.sha256 (buff).hexdigest ()

	return None

def file_get_sha256 (path):
	file_name = get_file_name (path)

	if not os.path.isfile (path):
		log_status (status.WARNING, 'File hash. Not found: "' + file_name + '"')
		return None

	hash_code = get_sha256 (path)

	if hash_code:
		log_status (status.SUCCESS, 'File hash: "' + os.path.basename (path) + '" - ' + hash_code)
		return hash_code + ' *' + os.path.basename (path) + '\n'

	log_status (status.FAILED, 'File hash. Failed: "' + file_name + '"')

	return None

def file_create (path, data):
	try:
		fn = open (path, 'w', newline='')

		if data:
			fn.write (data)

		fn.close ()

	except Exception as e:
		log_status (status.FAILED, 'Create file. Exception: "' + get_file_name (path) + '" (' + str (e) + ')')

	else:
		log_status (status.SUCCESS, 'Create file: "' + get_file_name (path) + '"')

def file_copy (src_file, dst_file, made_dir=True):
	if not os.path.isfile (src_file):
		log_status (status.FAILED, 'File copy. Not found: "' + get_file_name (src_file) + '"')
		return

	dst_dir = os.path.dirname (os.path.abspath (dst_file))
	file_name = get_file_name (dst_file)

	if not os.path.isdir (dst_dir):
		if made_dir:
			os.makedirs (dst_dir, exist_ok=True)
		else:
			log_status (status.WARNING, 'File copy. Dest directory: "' + get_file_name (dst_dir) + '" was not found.')
			return

	# Check file existence
	if os.path.isfile (dst_file):
		if get_sha256 (dst_file) == get_sha256 (src_file):
			log_status (status.WARNING, 'File copy. Not modified: "' + file_name + '"')
			return

	try:
		shutil.copyfile (src_file, dst_file)

	except Exception as e:
		log_status (status.FAILED, 'File copy. Exception: "' + file_name + '" (' + str (e) + ')')

	else:
		log_status (status.SUCCESS, 'File copy: "' + file_name + '"')

def file_remove (path):
	file_name = get_file_name (path)

	if not os.path.isfile (path):
		log_status (status.WARNING, 'File delete. Not found: "' + file_name + '"')
		return

	try:
		os.remove (path)

	except Exception as e:
		log_status (status.FAILED, 'File delete. Exception: "' + file_name + '" (' + str (e) + ')')

	else:
		log_status (status.SUCCESS, 'File delete: "' + file_name + '"')

def file_sign (path):
	if not os.path.isfile (path):
		log_status (status.FAILED, 'File sign. Not found: "' + get_file_name (path) + '"')
		return

	path_sign = path + '.sig'

	file_remove (path_sign)

	log_status (status.SUCCESS, 'File sign: "' + get_file_name (path) + '"')

	os.system ('gpg --output "' + path_sign + '" --detach-sign "' + path + '"')

def file_copy_mask (mask, dst_dir):
	for fn in glob.glob (mask):
		file_copy (fn, os.path.join (dst_dir, os.path.basename (fn)))

def file_sign_mask (mask):
	for fn in glob.glob (mask):
		file_sign (fn)

def dir_remove (path):
	if not os.path.isdir (path):
		log_status (status.FAILED, 'Directory delete. Not found: "' + get_file_name (path) + '"')
		return

	for fn in glob.glob (os.path.join (path, '*')):
		if os.path.isdir (fn):
			dir_remove (fn);
		else:
			file_remove (fn)

def file_pack_directory (out_file, directory):
	os.system ('7z.exe a -mm=Deflate64 -mx=9 -mfb=257 -mpass=15 -mmt=on -mtc=off -slp -bb1 "' + out_file + '" "' + directory + '"')

def initialize_helper ():
	# Colored terminal fix
	os.system ('')

	logging.basicConfig (level=logging.INFO)

#if __name__ == 'helper':
initialize_helper ()
