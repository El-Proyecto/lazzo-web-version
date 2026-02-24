# Google Maps Configuration

## API Key Setup

Para o Google Maps funcionar corretamente, é necessário configurar uma API key:

### 1. Obter API Key do Google Maps
1. Acede à [Google Cloud Console](https://console.cloud.google.com/)
2. Cria ou seleciona um projeto
3. Ativa as APIs:
   - Maps SDK for Android
   - Maps SDK for iOS
   - Geocoding API
4. Cria credenciais (API Key)
5. Restringe a API key aos teus packages/bundle IDs

### 2. Configurar no Android
No ficheiro `android/app/src/main/AndroidManifest.xml`, substitui `YOUR_API_KEY_HERE` pela tua API key:

```xml
<meta-data
    android:name="com.google.android.geo.API_KEY"
    android:value="AIzaSy..." />
```

### 3. Configurar no iOS
Adiciona no ficheiro `ios/Runner/Info.plist`:

```xml
<key>GMSApiKey</key>
<string>AIzaSy...</string>
```

### 4. Testar
- O Google Maps deve aparecer no retângulo quando selecionas uma localização
- Podes clicar no mapa para abrir no Google Maps externo
- O marcador vermelho indica a localização escolhida

## Funcionalidades Implementadas

✅ **Preview do Google Maps**: Mostra mapa real com marcador
✅ **Interatividade**: Clica no mapa para abrir Google Maps externo  
✅ **Permissões configuradas**: Android e iOS
✅ **Fallbacks**: Sem API key, o mapa não aparece mas a funcionalidade continua

## Troubleshooting

- **Mapa não aparece**: Verifica se a API key está configurada corretamente
- **Mapa cinzento**: Verifica se as APIs estão ativadas no Google Cloud Console
- **Erro de permissões**: Verifica se a API key tem as restrições corretas