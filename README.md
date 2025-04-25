# 📘 Meu Caderninho

Seu caderno de contas, moderno e inteligente — simples como anotar no papel, poderoso como um app completo!

---

## ✨ Funcionalidades

- ✅ Login com Google e e-mail/senha (via Firebase)
- ✅ Tela inicial com lista de grupos criados pelo usuário
- ✅ Criação, edição e exclusão de grupos
- ✅ Filtro e busca por nome de grupo
- ✅ Interface com Drawer (menu lateral com perfil e configurações)
- ✅ Integração com Firestore para persistência em tempo real
- ✅ Responsivo e funcional para Flutter Web

---

## 🚀 Tecnologias utilizadas

- [Flutter](https://flutter.dev/) 3.x
- [Firebase Auth](https://firebase.google.com/products/auth)
- [Cloud Firestore](https://firebase.google.com/products/firestore)
- [Google Sign-In](https://pub.dev/packages/google_sign_in)

---

## 🧪 Como rodar localmente

```bash
# Instale as dependências
flutter pub get

# Rode localmente no navegador
flutter run -d web-server --web-hostname=localhost --web-port=8080
```

> Para login com Google funcionar, use **localhost** ou um domínio HTTPS com o Client ID configurado.

---

## 📦 Organização de pastas

```bash
lib/
├── screens/           # Telas (login, cadastro, grupos, etc)
├── widgets/           # Componentes reutilizáveis (CustomDrawer)
├── services/          # Serviços e integrações futuras
├── main.dart          # Entrada do app
```

---

## 💡 Próximos passos

- [ ] Compartilhamento de grupos
- [ ] Marcação de despesas
- [ ] Modo escuro
- [ ] Deploy em produção com Firebase Hosting

---

## 🙋‍♀️ Desenvolvido por Fernanda Peixoto

> [LinkedIn](https://www.linkedin.com/in/fernandapeixoto-b0b92031) · [GitHub](https://github.com/seu_usuario)