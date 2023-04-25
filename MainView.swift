import SwiftUI
import Security

struct Website: Identifiable {
    let id = UUID()
    let name: String
    let username: String
    let password: String
}

class PasswordManager: ObservableObject {
    @Published var websites: [Website] = []
    
    func addWebsite(name: String, username: String, password: String) {
        let website = Website(name: name, username: username, password: password)
        websites.append(website)
    }
    
    func getWebsitesByURL() -> [String: [Website]] {
        var websitesByURL: [String: [Website]] = [:]
        for website in websites {
            if websitesByURL[website.name] != nil {
                websitesByURL[website.name]?.append(website)
            } else {
                websitesByURL[website.name] = [website]
            }
        }
        return websitesByURL
    }
    
    func importPasswordsFromSystem() {
        let query: [String: Any] = [
            kSecClass as String: kSecClassInternetPassword,
            kSecMatchLimit as String: kSecMatchLimitAll,
            kSecReturnAttributes as String: true,
            kSecReturnData as String: true
        ]
        
        var result: AnyObject?
        let status = withUnsafeMutablePointer(to: &result) {
            SecItemCopyMatching(query as CFDictionary, UnsafeMutablePointer($0))
        }
        
        guard status == errSecSuccess else {
            print("Error importing password: \(status)")
            return
        }
        
        guard let items = result as? [[String: Any]] else { return }
        
        for item in items {
            guard let nameData = item[kSecAttrServer as String] as? Data else { continue }
            guard let usernameData = item[kSecAttrAccount as String] as? Data else { continue }
            guard let passwordData = item[kSecValueData as String] as? Data else { continue }
            
            let name = String(data: nameData, encoding: .utf8)!
            let username = String(data: usernameData, encoding: .utf8)!
            let password = String(data: passwordData, encoding: .utf8)!
            
            addWebsite(name: name, username: username, password: password)
        }
    }
}

struct MainView: View {
    @ObservedObject var passwordManager: PasswordManager = PasswordManager()
    @State private var showAddPasswords = false
    
    var body: some View {
        NavigationView {
            List {
                ForEach(Array(passwordManager.getWebsitesByURL().keys).sorted(), id: \.self) { key in
                    Section(header: Text(key)) {
                        ForEach(passwordManager.getWebsitesByURL()[key]!) { website in
                            Text("\(website.username) : \(website.password)")
                        }
                    }
                }
            }
            .navigationBarTitle(Text("Passwords"))
            .navigationBarItems(trailing:
                                    Button(action: {
                showAddPasswords = true
            }) {
                Image(systemName: "plus")
            }
            )
            .sheet(isPresented: $showAddPasswords) {
                AddPasswordsView(passwordManager: passwordManager)
            }
            .onAppear {
                passwordManager.importPasswordsFromSystem()
            }
        }
    }
}

struct AddPasswordsView: View {
    @ObservedObject var passwordManager: PasswordManager
    @State private var website = ""
    @State private var username = ""
    @State private var password = ""
    
    var body: some View {
        VStack {
            HStack {
                Text("Website:")
                TextField("Enter website", text: $website)
            }
            .padding()
            
            HStack {
                Text("Username:")
                TextField("Enter username", text: $username)
            }
            .padding()
            
            HStack {
                Text("Password:")
                SecureField("Enter password", text: $password)
            }
            .padding()
            
            Button(action: addPassword) {
                Text("Add Password")
            }
            .padding()
        }
    }
    
    func addPassword() {
        passwordManager.addWebsite(name: website, username: username, password: password)
        website = ""
        username = ""
        password = ""
    }
}


struct PasswordItem: Codable {
    var website: String
    var username: String
    var password: String
}
