import os
import logging
import zipfile

logger = logging.getLogger(__name__)

def compress_to_zip(output_dir, zip_filename):    
    zip_file_path = f"{output_dir}/{zip_filename}.zip"
    with zipfile.ZipFile(zip_file_path, 'w') as zipf:
        for root, dirs, files in os.walk(output_dir):
            for file in files:
                if file.endswith('.csv'):
                    zipf.write(os.path.join(root, file), file)
    logger.info(f"Compressed CSV files to {zip_file_path}")
    return zip_file_path
