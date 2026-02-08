exports.handler = async (event) => { console.log('Processando vídeo:', JSON.stringify(event)); return { statusCode: 200, body: 'Sucesso' }; };
