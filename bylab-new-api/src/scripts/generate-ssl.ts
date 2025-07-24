import forge from 'node-forge';
import fs from 'fs';
import path from 'path';

const sslDir = path.join(__dirname, '../../ssl');

// Criar diretório SSL se não existir
if (!fs.existsSync(sslDir)) {
    fs.mkdirSync(sslDir);
}

console.log('Gerando certificados SSL...');

try {
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

    // Converter para PEM
    const privateKeyPem = forge.pki.privateKeyToPem(keys.privateKey);
    const certificatePem = forge.pki.certificateToPem(cert);

    // Salvar arquivos
    fs.writeFileSync(path.join(sslDir, 'private.key'), privateKeyPem);
    fs.writeFileSync(path.join(sslDir, 'certificate.crt'), certificatePem);

    console.log('Certificados SSL gerados com sucesso!');
    console.log('Localização dos arquivos:');
    console.log('- Chave privada: ssl/private.key');
    console.log('- Certificado: ssl/certificate.crt');
} catch (error) {
    console.error('Erro ao gerar certificados:', error);
} 