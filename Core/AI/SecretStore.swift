import Foundation
import Security
protocol SecretStore {
 func readSecret(for key: String) throws -> String?
 func saveSecret(_ value: String, for key: String) throws
 func deleteSecret(for key: String) throws
}
enum SecretStoreError: Error { case unexpectedStatus(OSStatus) }
final class KeychainSecretStore: SecretStore {
 private let service: String
 init(service: String = Bundle.main.bundleIdentifier ?? "com.eduardtavalbi.lmr") { self.service = service }
 func readSecret(for key: String) throws -> String? {
  var query = baseQuery(for: key); query[kSecReturnData as String] = true; query[kSecMatchLimit as String] = kSecMatchLimitOne
  var result: CFTypeRef?; let status = SecItemCopyMatching(query as CFDictionary, &result)
  if status == errSecItemNotFound { return nil }
  guard status == errSecSuccess else { throw SecretStoreError.unexpectedStatus(status) }
  guard let data = result as? Data else { return nil }; return String(data: data, encoding: .utf8)
 }
 func saveSecret(_ value: String, for key: String) throws {
  let query = baseQuery(for: key); let attributes = [kSecValueData as String: Data(value.utf8)]
  let status = SecItemUpdate(query as CFDictionary, attributes as CFDictionary)
  if status == errSecItemNotFound {
   var insert = query; insert[kSecValueData as String] = Data(value.utf8)
   insert[kSecAttrAccessible as String] = kSecAttrAccessibleWhenUnlockedThisDeviceOnly
   let result = SecItemAdd(insert as CFDictionary, nil)
   guard result == errSecSuccess else { throw SecretStoreError.unexpectedStatus(result) }
  } else if status != errSecSuccess { throw SecretStoreError.unexpectedStatus(status) }
 }
 func deleteSecret(for key: String) throws {
  let status = SecItemDelete(baseQuery(for: key) as CFDictionary)
  guard status == errSecSuccess || status == errSecItemNotFound else { throw SecretStoreError.unexpectedStatus(status) }
 }
 private func baseQuery(for key: String) -> [String: Any] {
  [kSecClass as String: kSecClassGenericPassword, kSecAttrService as String: service, kSecAttrAccount as String: key]
 }
}
