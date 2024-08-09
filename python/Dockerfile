# Use the official Python image as a parent image
FROM python:3.11

# Set the working directory to /app
WORKDIR /app

# Copy the current directory contents into the container at /app
COPY . .

# Install any needed packages specified in requirements.txt
RUN pip install -r requirements.txt

# Run main.py with '-u' flag to disable output buffering and make print statements work
CMD ["python", "-u", "main.py"]