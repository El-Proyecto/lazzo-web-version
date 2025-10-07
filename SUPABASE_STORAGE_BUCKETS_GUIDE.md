# 📸 Supabase Storage - Logística de Buckets para Fotos de Grupos

## 🏗️ **Arquitetura de Storage**

### **1. Estrutura de Buckets**

```
Supabase Storage
├── group-photos/           # Bucket principal para fotos de grupos
│   ├── {group_id}/         # Pasta por grupo (UUID)
│   │   ├── cover.jpg       # Foto de capa atual
│   │   ├── cover_thumb.jpg # Thumbnail da capa (150x150)
│   │   └── uploads/        # Uploads temporários/histórico
│   │       ├── {user_id}_{timestamp}.jpg
│   │       └── {user_id}_{timestamp}.jpg
│   └── temp/               # Uploads temporários antes de aprovação
│       └── {upload_id}.jpg
└── profile-photos/         # Para fotos de perfil de utilizadores
    └── {user_id}/
        ├── avatar.jpg
        └── avatar_thumb.jpg
```

---

## 📱 **Fluxo de Upload de Foto de Grupo**

### **Processo Completo:**

#### **1. Seleção da Foto pelo Utilizador**
```dart
// Utilizador seleciona foto via GroupPhotoSelector widget
final ImagePicker picker = ImagePicker();
final XFile? image = await picker.pickFromGallery();

if (image != null) {
  // Comprimir imagem para reduzir tamanho
  final compressedImage = await _compressImage(image);
  
  // Upload para Supabase
  final photoUrl = await _uploadGroupPhoto(compressedImage, groupId);
}
```

#### **2. Upload para Supabase Storage**
```dart
// Em GroupsDataSource
Future<String?> uploadGroupPhoto(String imagePath, String groupId) async {
  try {
    // Gerar nome único para a foto
    final fileName = 'cover_${DateTime.now().millisecondsSinceEpoch}.jpg';
    final path = '$groupId/$fileName';
    
    // Upload do arquivo
    final file = File(imagePath);
    await _client.storage
        .from('group-photos')
        .upload(path, file);

    // Obter URL pública
    final publicUrl = _client.storage
        .from('group-photos')
        .getPublicUrl(path);

    // Atualizar campo photo_url na tabela groups
    await _client
        .from('groups')
        .update({'photo_url': publicUrl})
        .eq('id', groupId);

    return publicUrl;
  } catch (e) {
    print('Erro no upload: $e');
    return null;
  }
}
```

#### **3. Otimização e Compressão**
```dart
Future<File> _compressImage(XFile image) async {
  // Comprimir para máximo 1MB e 800x800px
  final compressedImage = await FlutterImageCompress.compressAndGetFile(
    image.path,
    '${Directory.systemTemp.path}/compressed_${DateTime.now().millisecondsSinceEpoch}.jpg',
    quality: 85,
    minWidth: 400,
    minHeight: 400,
    format: CompressFormat.jpeg,
  );
  
  return File(compressedImage!.path);
}
```

---

## 🔐 **Políticas RLS (Row Level Security)**

### **Bucket `group-photos` Policies:**

#### **1. Upload Policy (INSERT)**
```sql
CREATE POLICY "Members can upload group photos" ON storage.objects
FOR INSERT WITH CHECK (
  bucket_id = 'group-photos' AND
  -- Verificar se o utilizador é membro do grupo
  (storage.foldername(name))[1] IN (
    SELECT group_id::text FROM group_members 
    WHERE user_id = auth.uid()
  )
);
```

#### **2. View Policy (SELECT)**
```sql
CREATE POLICY "Anyone can view group photos" ON storage.objects
FOR SELECT USING (
  bucket_id = 'group-photos'
);
-- Fotos de grupos são públicas para todos verem
```

#### **3. Update Policy (UPDATE)**
```sql
CREATE POLICY "Group admins can update photos" ON storage.objects
FOR UPDATE USING (
  bucket_id = 'group-photos' AND
  -- Apenas admins podem alterar
  (storage.foldername(name))[1] IN (
    SELECT group_id::text FROM group_members 
    WHERE user_id = auth.uid() AND role = 'admin'
  )
);
```

#### **4. Delete Policy (DELETE)**
```sql
CREATE POLICY "Group admins can delete photos" ON storage.objects
FOR DELETE USING (
  bucket_id = 'group-photos' AND
  -- Apenas admins podem apagar
  (storage.foldername(name))[1] IN (
    SELECT group_id::text FROM group_members 
    WHERE user_id = auth.uid() AND role = 'admin'
  )
);
```

---

## 📊 **Configuração do Bucket**

### **Configurações Recomendadas:**

```javascript
// No Supabase Dashboard > Storage > Settings
{
  "bucket_name": "group-photos",
  "public": true,              // URLs públicas
  "file_size_limit": 5242880,  // 5MB máximo
  "allowed_mime_types": [
    "image/jpeg",
    "image/png", 
    "image/webp"
  ],
  "transform_enabled": true,    // Para thumbnails automáticos
  "resize_options": {
    "thumbnail": "150x150",
    "medium": "400x400",
    "large": "800x800"
  }
}
```

---

## 🚀 **Implementação Step-by-Step**

### **1. Criar Bucket no Supabase**
```sql
-- Via SQL ou Dashboard
INSERT INTO storage.buckets (id, name, public)
VALUES ('group-photos', 'group-photos', true);
```

### **2. Aplicar Políticas RLS**
```sql
-- Executar as políticas listadas acima
-- Via SQL Editor no Supabase Dashboard
```

### **3. Configurar Upload no App**
```dart
// Adicionar ao GroupsDataSource
class SupabaseGroupsDataSource {
  Future<String?> uploadGroupPhoto(String imagePath, String groupId) async {
    // Implementação do upload
  }
  
  Future<void> deleteGroupPhoto(String groupId) async {
    // Apagar foto anterior antes de fazer upload de nova
  }
}
```

### **4. Integrar na UI**
```dart
// No GroupPhotoSelector widget
onPhotoSelected: (XFile photo) async {
  setState(() => _isUploading = true);
  
  final photoUrl = await ref
    .read(groupRepositoryProvider)
    .uploadGroupPhoto(photo.path, widget.groupId);
    
  if (photoUrl != null) {
    widget.onPhotoUploaded(photoUrl);
  }
  
  setState(() => _isUploading = false);
}
```

---

## 🔧 **Funcionalidades Avançadas**

### **1. Thumbnails Automáticos**
```javascript
// Supabase Edge Function para gerar thumbnails
export default async function handler(req: Request) {
  const { groupId, originalUrl } = await req.json();
  
  // Gerar thumbnail 150x150
  const thumbnail = await generateThumbnail(originalUrl, 150, 150);
  
  // Upload thumbnail
  const thumbPath = `${groupId}/cover_thumb.jpg`;
  await supabase.storage
    .from('group-photos')
    .upload(thumbPath, thumbnail);
    
  return new Response(JSON.stringify({ success: true }));
}
```

### **2. Cache e Performance**
```dart
// Cache de URLs para evitar requests desnecessários
class PhotoCache {
  static final Map<String, String> _cache = {};
  
  static String? getCachedUrl(String groupId) => _cache[groupId];
  
  static void cacheUrl(String groupId, String url) {
    _cache[groupId] = url;
  }
}
```

### **3. Gestão de Espaço**
```sql
-- Limpeza automática de fotos antigas (via cron job)
DELETE FROM storage.objects 
WHERE bucket_id = 'group-photos' 
  AND created_at < NOW() - INTERVAL '30 days'
  AND name LIKE '%/uploads/%';
```

---

## 📈 **Métricas e Monitorização**

### **Analytics de Storage:**
- **Total space used** por grupo
- **Upload frequency** por utilizador
- **Popular image formats**
- **Average file sizes**

### **Queries Úteis:**
```sql
-- Tamanho total por grupo
SELECT 
  (metadata->>'groupId') as group_id,
  SUM((metadata->>'size')::bigint) as total_bytes
FROM storage.objects 
WHERE bucket_id = 'group-photos'
GROUP BY (metadata->>'groupId');

-- Uploads por utilizador
SELECT 
  (metadata->>'uploadedBy') as user_id,
  COUNT(*) as upload_count
FROM storage.objects 
WHERE bucket_id = 'group-photos'
  AND created_at > NOW() - INTERVAL '7 days'
GROUP BY (metadata->>'uploadedBy');
```

---

## ⚠️ **Considerações de Segurança**

### **1. Validação de Conteúdo**
- **Verificar formato** (apenas JPEG, PNG, WebP)
- **Escanear por malware** (opcional)
- **Limitar tamanho** (máx 5MB)
- **Verificar dimensões** (mín 150x150, máx 2048x2048)

### **2. Rate Limiting**
```sql
-- Limitar uploads por utilizador (5 por hora)
CREATE OR REPLACE FUNCTION check_upload_limit()
RETURNS TRIGGER AS $$
BEGIN
  IF (
    SELECT COUNT(*) 
    FROM storage.objects 
    WHERE bucket_id = NEW.bucket_id 
      AND (metadata->>'uploadedBy') = auth.uid()::text
      AND created_at > NOW() - INTERVAL '1 hour'
  ) >= 5 THEN
    RAISE EXCEPTION 'Upload limit exceeded';
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;
```

### **3. Backup e Recovery**
- **Backup automático** das fotos críticas
- **Replicação cross-region** para alta disponibilidade
- **Histórico de alterações** para audit trail

---

## ✅ **Checklist de Implementação**

- [ ] **Bucket criado** com configurações corretas
- [ ] **Políticas RLS aplicadas** para segurança
- [ ] **Upload function implementada** no data source
- [ ] **Compressão de imagens** configurada
- [ ] **UI integrada** no GroupPhotoSelector
- [ ] **Error handling** para falhas de upload
- [ ] **Loading states** durante upload
- [ ] **Cache implementado** para performance
- [ ] **Thumbnails gerados** automaticamente
- [ ] **Limpeza automática** de ficheiros antigos

---

## 🎯 **Benefícios da Arquitetura**

✅ **Escalabilidade** - Buckets separados por funcionalidade  
✅ **Segurança** - RLS garante acesso apenas a membros  
✅ **Performance** - CDN global + cache local  
✅ **Flexibilidade** - Suporte a múltiplos formatos  
✅ **Custo-eficiência** - Pagamento por uso real  
✅ **Manutenção** - Limpeza automática de ficheiros antigos  

**Esta arquitetura suporta milhares de grupos e milhões de fotos com segurança e performance otimizadas! 🚀**