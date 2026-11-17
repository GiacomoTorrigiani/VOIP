import SwiftUI
import ContactsUI

public struct ContactPickerView: UIViewControllerRepresentable {
    public var onSelectContact: (_ name: String, _ phoneNumber: String) -> Void
    @Environment(\.presentationMode) private var presentationMode

    public init(onSelectContact: @escaping (_ name: String, _ phoneNumber: String) -> Void) {
        self.onSelectContact = onSelectContact
    }

    public func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    public func makeUIViewController(context: Context) -> CNContactPickerViewController {
        let picker = CNContactPickerViewController()
        picker.delegate = context.coordinator
        picker.displayedPropertyKeys = [CNContactPhoneNumbersKey]
        return picker
    }

    public func updateUIViewController(_ uiViewController: CNContactPickerViewController, context: Context) {}

    public class Coordinator: NSObject, CNContactPickerDelegate {
        var parent: ContactPickerView

        init(_ parent: ContactPickerView) {
            self.parent = parent
        }

        public func contactPicker(_ picker: CNContactPickerViewController, didSelect contact: CNContact) {
            var fullName = "\(contact.givenName) \(contact.familyName)".trimmingCharacters(in: .whitespaces)
            if fullName.isEmpty {
                fullName = contact.organizationName.trimmingCharacters(in: .whitespaces)
            }
            if fullName.isEmpty {
                fullName = "Contatto"
            }

            var selectedNumber = ""
            if let firstPhone = contact.phoneNumbers.first?.value.stringValue {
                selectedNumber = cleanPhoneNumber(firstPhone)
            }

            parent.onSelectContact(fullName, selectedNumber)
            parent.presentationMode.wrappedValue.dismiss()
        }

        public func contactPicker(_ picker: CNContactPickerViewController, didSelect contactProperty: CNContactProperty) {
            if contactProperty.key == CNContactPhoneNumbersKey,
               let phoneValue = contactProperty.value as? CNPhoneNumber {
                let contact = contactProperty.contact
                var fullName = "\(contact.givenName) \(contact.familyName)".trimmingCharacters(in: .whitespaces)
                if fullName.isEmpty { fullName = contact.organizationName }
                if fullName.isEmpty { fullName = "Contatto" }

                let cleanNumber = cleanPhoneNumber(phoneValue.stringValue)
                parent.onSelectContact(fullName, cleanNumber)
                parent.presentationMode.wrappedValue.dismiss()
            }
        }

        public func contactPickerDidCancel(_ picker: CNContactPickerViewController) {
            parent.presentationMode.wrappedValue.dismiss()
        }

        private func cleanPhoneNumber(_ raw: String) -> String {
            return raw.replacingOccurrences(of: " ", with: "")
                .replacingOccurrences(of: "-", with: "")
                .replacingOccurrences(of: "(", with: "")
                .replacingOccurrences(of: ")", with: "")
        }
    }
}
