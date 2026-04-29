# SSL / TLS Reference

## Resources

- [Add CA to Ubuntu](https://superuser.com/questions/437330/how-do-you-add-a-certificate-authority-ca-to-ubuntu)
- [Nginx self signed certificate in Ubuntu](https://www.digitalocean.com/community/tutorials/how-to-create-a-self-signed-ssl-certificate-for-nginx-in-ubuntu-20-04-1) 
- [Certificate signing request](https://www.digicert.com/kb/csr-ssl-installation/nginx-openssl.htm)

---

## Certificate Authority (CA)

A CA is a trusted entity that issues digital certificates. In self-signed setups, you act as your own CA.

> **Note:** The CA and SAN must match across all certificates in the chain.

---

## Subject Alternative Name (SAN)

SAN entries define the valid identities for a certificate:

```
IP:<ip-address>
DNS:<domain>
```

### Generate a Self-Signed Certificate with SAN

```bash
sudo openssl req -x509 -nodes -days 365 \
  -addext "subjectAltName = IP:127.0.0.1, DNS:localhost" \
  -newkey rsa:2048 \
  -keyout private/temp.key \
  -out /certs/temp.crt
```

---

## Install SSL on Frontend and Backend (Linux)

1. **Generate keys** using the `openssl` command above.
2. **Self-signed certs:** On the frontend server, store the backend's public certificate and verify it is trusted:
  ```bash
   curl https://<backend-hostname>
  ```
3. **Add certificates to Chrome** for both frontend and backend (see section below).

---

## Add a Certificate to Chrome

- **From a browser warning page:** Click the warning/error icon to view and export the certificate.
- **From DevTools console:** Click the failing HTTPS request URL, or paste it directly in the address bar, then inspect the certificate via the padlock icon in the top-left.

