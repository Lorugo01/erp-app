const forge = require('node-forge');
const fs = require('fs');
const path = require('path');

// Criar diretório SSL se não existir
const sslDir = path.join(__dirname, '../../ssl');
if (!fs.existsSync(sslDir)) {
    fs.mkdirSync(sslDir);
}

// Gerar par de chaves
const keys = forge.pki.rsa.generateKeyPair(2048);

// Criar certificado
const cert = forge.pki.createCertificate();
cert.publicKey = keys.publicKey;
cert.serialNumber = '01';
cert.validity.notBefore = new Date();
cert.validity.notAfter = new Date();
cert.validity.notAfter.setFullYear(cert.validity.notBefore.getFullYear() + 1);

const attrs = [{
    name: 'commonName',
    value: 'localhost'
}, {
    name: 'countryName',
    value: 'BR'
}, {
    shortName: 'ST',
    value: 'Estado'
}, {
    name: 'localityName',
    value: 'Cidade'
}, {
    name: 'organizationName',
    value: 'Bylab'
}, {
    shortName: 'OU',
    value: 'Development'
}];

cert.setSubject(attrs);
cert.setIssuer(attrs);
cert.sign(keys.privateKey);

// Exportar certificado e chave privada
const certPem = forge.pki.certificateToPem(cert);
const privateKeyPem = forge.pki.privateKeyToPem(keys.privateKey);

fs.writeFileSync(path.join(sslDir, 'certificate.crt'), certPem);
fs.writeFileSync(path.join(sslDir, 'private.key'), privateKeyPem);

console.log('Certificados SSL gerados com sucesso!'); 