import SwiftUI

struct EmergencyView: View {
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    Group {
                        SectionHeader(text: "Physical & Mental Health")
                        EmergencyItem(
                            title: "University Health Centre (Clinic)",
                            phone: "+65 6601 5035",
                            email: "uhc_health@nus.edu.sg"
                        )
                        EmergencyItem(
                            title: "Counselling Services",
                            phone: "+65 6516 2376",
                            email: "uhc_counselling@nus.edu.sg"
                        )
                        EmergencyItem(
                            title: "Lifeline NUS (24h Psychological Emergency)",
                            phone: "+65 6516 7777"
                        )
                    }

                    Group {
                        SectionHeader(text: "Sexual Misconduct")
                        EmergencyItem(
                            title: "NUS Care Unit (24h line)",
                            phone: "+65 6601 4000",
                            email: "ncu_help@nus.edu.sg",
                            link: "https://care.nus.edu.sg/"
                        )
                    }

                    Group {
                        SectionHeader(text: "Campus Security")
                        EmergencyItem(
                            title: "Office of Campus Security (24h)",
                            phone: "+65 6874 1616",
                            email: "ocssec@nus.edu.sg"
                        )
                    }

                    Group {
                        SectionHeader(text: "Off-Campus Mental Health Support")
                        EmergencyItem(title: "Samaritans of Singapore (24h)", phone: "1800 221 1767", email: "pat@sos.org.sg", link: "https://www.sos.org.sg/")
                        EmergencyItem(title: "Community Mental Health Team (CHAT)", phone: "+65 6493 6500", email: "CHAT@mentalhealth.sg")
                        EmergencyItem(title: "Brahm Centre Helpline (Office)", phone: "+65 6655 0000")
                        EmergencyItem(title: "Brahm Centre (After Hours)", phone: "+65 8823 0000")
                        EmergencyItem(title: "AWARE Women’s Helpline", phone: "1800 777 5555")
                        EmergencyItem(title: "Sexual Assault Care Centre", phone: "+65 6779 0282")
                        EmergencyItem(title: "IMH Helpline (24h)", phone: "6389 2222", link: "https://www.imh.com.sg/")
                        EmergencyItem(title: "Singapore Assoc. of Mental Health", phone: "1800 283 7019", link: "https://www.samhealth.org.sg/")
                    }
                }
                .padding()
            }
            .navigationTitle("Emergency")
            .background(Color("BGColor").ignoresSafeArea())
        }
    }
}

struct EmergencyItem: View {
    let title: String
    let phone: String?
    let email: String?
    let link: String?

    init(title: String, phone: String? = nil, email: String? = nil, link: String? = nil) {
        self.title = title
        self.phone = phone
        self.email = email
        self.link = link
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.headline)
                .foregroundColor(Color("FontColor"))

            if let phone = phone, let telURL = URL(string: "tel:\(phone.replacingOccurrences(of: " ", with: ""))") {
                Link("📞 \(phone)", destination: telURL)
                    .font(.subheadline)
                    .foregroundColor(.black)
            }


            if let email = email, let mailURL = URL(string: "mailto:\(email)") {
                Link("✉️ \(email)", destination: mailURL)
                    .font(.subheadline)
                    .foregroundColor(.black)
            }

            if let link = link, let url = URL(string: link) {
                Link("🌐 Visit site", destination: url)
                    .font(.subheadline)
                    .foregroundColor(.blue)
            }
        }
        .padding(.bottom, 12)
    }
}

struct SectionHeader: View {
    let text: String
    var body: some View {
        Text(text)
            .font(.title3.bold())
            .foregroundColor(Color("FontColor"))
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}
