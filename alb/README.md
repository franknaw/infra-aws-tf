
###ALB

The Application Load Balancer performs the following tasks.

1. Generate a self-signed certificate.  This can be disabled if using a pre-existing certificate. 
2. Provision the ALB
3. Provision the ALB Target Groups and attachments
4. Provision the ALB listener "HTTPS"
5. Provision the ALB listener rules.

The "genCert.sh" script is called by the "provision.sh" script during the apply process.  There is a flag in the gen cert script to bypass the certificate generation.


