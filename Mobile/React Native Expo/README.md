---
tags: [mobile]
categoria: "Mobile"
---

# React Native + Expo — Desenvolvimento Mobile

**Stack recomendada:** Expo SDK 52+ com Expo Router (file-based routing)  
**Princípio:** Expo first. Só ejetar para bare workflow se realmente necessário.

---

## Setup com Expo

```bash
npx create-expo-app meu-app --template
cd meu-app
npx expo start
```

---

## Estrutura com Expo Router

```
app/
├── (tabs)/           ← grupo de rotas com tabs
│   ├── _layout.tsx   ← configura as tabs
│   ├── index.tsx     ← tab Home
│   └── profile.tsx   ← tab Perfil
├── (auth)/
│   ├── _layout.tsx
│   ├── login.tsx
│   └── register.tsx
├── _layout.tsx       ← layout raiz (providers, etc)
└── +not-found.tsx
```

---

## Layout Raiz e Navegação

```tsx
// app/_layout.tsx
import { Stack } from 'expo-router'
import { useColorScheme } from 'react-native'

export default function RootLayout() {
  return (
    <Stack>
      <Stack.Screen name="(tabs)"  options={{ headerShown: false }} />
      <Stack.Screen name="(auth)"  options={{ headerShown: false }} />
      <Stack.Screen name="modal"   options={{ presentation: 'modal' }} />
    </Stack>
  )
}

// app/(tabs)/_layout.tsx
import { Tabs } from 'expo-router'
import { House, User, Settings } from 'lucide-react-native'

export default function TabsLayout() {
  return (
    <Tabs screenOptions={{ tabBarActiveTintColor: '#7c3aed' }}>
      <Tabs.Screen name="index"   options={{ title: 'Início',  tabBarIcon: ({ color }) => <House color={color} /> }} />
      <Tabs.Screen name="profile" options={{ title: 'Perfil',  tabBarIcon: ({ color }) => <User  color={color} /> }} />
    </Tabs>
  )
}
```

---

## Componentes Nativos Essenciais

```tsx
import {
  View, Text, StyleSheet, ScrollView,
  TouchableOpacity, Pressable,
  FlatList, SectionList,
  TextInput, Image, Modal,
  ActivityIndicator, RefreshControl,
  Platform, Dimensions, StatusBar,
} from 'react-native'

// FlatList — lista performática (virtualizada)
<FlatList
  data={users}
  keyExtractor={(item) => item.id}
  renderItem={({ item }) => <UserCard user={item} />}
  ItemSeparatorComponent={() => <View style={{ height: 8 }} />}
  ListEmptyComponent={<Text>Nenhum usuário</Text>}
  refreshControl={
    <RefreshControl refreshing={loading} onRefresh={fetchUsers} />
  }
  onEndReached={loadMore}       // paginação infinita
  onEndReachedThreshold={0.5}
/>

// Platform-specific
const styles = StyleSheet.create({
  container: {
    flex: 1,
    paddingTop: Platform.OS === 'android' ? StatusBar.currentHeight : 0,
    paddingHorizontal: 16,
  },
})
```

---

## NativeWind (Tailwind no React Native)

```tsx
// NativeWind v4 — classes Tailwind no RN
import { View, Text, Pressable } from 'react-native'

export function Button({ label, onPress, variant = 'primary' }) {
  return (
    <Pressable
      onPress={onPress}
      className={`
        rounded-xl px-6 py-3 items-center
        ${variant === 'primary'     ? 'bg-violet-600' : ''}
        ${variant === 'destructive' ? 'bg-red-500'    : ''}
        ${variant === 'outline'     ? 'border border-gray-300 bg-transparent' : ''}
      `}
    >
      <Text className="text-white font-semibold text-base">{label}</Text>
    </Pressable>
  )
}
```

---

## Persistência — AsyncStorage e SecureStore

```typescript
import AsyncStorage from '@react-native-async-storage/async-storage'
import * as SecureStore from 'expo-secure-store'

// AsyncStorage — dados não-sensíveis
await AsyncStorage.setItem('preferences', JSON.stringify({ theme: 'dark' }))
const prefs = JSON.parse(await AsyncStorage.getItem('preferences') ?? '{}')

// SecureStore — tokens e dados sensíveis (criptografado)
await SecureStore.setItemAsync('auth_token', token)
const token = await SecureStore.getItemAsync('auth_token')
await SecureStore.deleteItemAsync('auth_token')
```

---

## Notificações Push com Expo

```typescript
import * as Notifications from 'expo-notifications'
import * as Device from 'expo-device'

Notifications.setNotificationHandler({
  handleNotification: async () => ({
    shouldShowAlert: true,
    shouldPlaySound: true,
    shouldSetBadge: false,
  }),
})

async function registerForPushNotifications() {
  if (!Device.isDevice) return null

  const { status } = await Notifications.requestPermissionsAsync()
  if (status !== 'granted') return null

  const token = (await Notifications.getExpoPushTokenAsync()).data
  return token  // salvar no backend
}
```

---

## Animações com Reanimated

```tsx
import Animated, {
  useAnimatedStyle, useSharedValue,
  withSpring, withTiming, interpolate,
  FadeIn, SlideInRight,
} from 'react-native-reanimated'

function AnimatedCard() {
  const scale  = useSharedValue(1)
  const opacity = useSharedValue(1)

  const animatedStyle = useAnimatedStyle(() => ({
    transform: [{ scale: scale.value }],
    opacity: opacity.value,
  }))

  return (
    <Animated.View
      style={animatedStyle}
      entering={FadeIn.duration(300)}
    >
      <Pressable
        onPressIn  ={() => { scale.value  = withSpring(0.95) }}
        onPressOut ={() => { scale.value  = withSpring(1) }}
      >
        <Text>Card animado</Text>
      </Pressable>
    </Animated.View>
  )
}
```

---

## EAS Build — Publicar nas Lojas

```bash
npm install -g eas-cli
eas login
eas build:configure

# Build para testes internos
eas build --platform android --profile preview
eas build --platform ios     --profile preview

# Build para publicar nas lojas
eas build --platform all --profile production

# Submeter para as lojas
eas submit --platform android
eas submit --platform ios
```

---

## Referências

→ `references/navigation-patterns.md` — Deep links, autenticação com navegação, gestos avançados


---

## Relacionado

[[React 19]] | [[TypeScript]]


---

## Referencias

- [[Referencias/extra]]
