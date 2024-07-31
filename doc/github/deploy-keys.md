# Deploy Keys

## Ubuntu
How to use deploy key in ubuntu

### 1. Generate SSH Key Pair
First, generate an SSH key pair on your EC2 instance.

```bash
ssh-keygen -t rsa -b 4096 -C "your_email@example.com"
```

### 2. Add the Deploy Key to GitHub
Next, add the generated public key (id_rsa.pub) as a deploy key to your GitHub repository.

1. Copy the contents of your public key to the clipboard:

```bash
cat ~/.ssh/id_rsa.pub
```

2. Go to your GitHub repository on the web.

3. Navigate to Settings > Deploy keys.

4. Click Add deploy key.

5. Provide a title and paste the contents of your public key.

6. Check the Allow write access box if you need write access (optional).

7. Click Add key.

### 3. Add the Private Key to the SSH Agent
To use the private key for authentication, add it to the SSH agent:

```bash
eval "$(ssh-agent -s)"
ssh-add ~/.ssh/id_rsa
```

### 4. Configure SSH to Use the Key
Create or modify the ~/.ssh/config file to specify which key to use for GitHub.

```bash
nano ~/.ssh/config
```

Add the following lines to the file:

```plaintext
Host github.com
  IdentityFile ~/.ssh/id_rsa
  User git
```

### 5. Clone the Repository
Now you should be able to clone your repository using the SSH URL:

```bash
git clone git@github.com:your_username/your_repository.git
```

### Summary of Steps
1. Generate an SSH key pair on your EC2 instance.
2. Add the public key as a deploy key to your GitHub repository.
3. Add the private key to the SSH agent.
4. Configure SSH to use the key for GitHub.
5. Clone the repository using the SSH URL.