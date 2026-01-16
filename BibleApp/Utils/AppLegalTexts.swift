import Foundation

/// App legal documents and information for Selah Bible App
enum AppLegalTexts {
    
    // MARK: - App Info
    static let appName = "Selah"
    static let appTagline = "가장 고요한 성경"
    static let appTaglineEN = "Scripture in Stillness"
    static let developerEmail = "jiwoong.net@gmail.com"
    static let appVersion = "1.0.0"
    
    // MARK: - Privacy Policy
    
    static func privacyPolicy(isKorean: Bool) -> String {
        isKorean ? privacyPolicyKR : privacyPolicyEN
    }
    
    private static let privacyPolicyKR = """
    개인정보 처리방침
    
    최종 업데이트: 2025년 1월
    
    셀라(Selah)는 사용자의 개인정보를 소중히 여기며, 관련 법령에 따라 개인정보를 보호하기 위해 최선을 다하고 있습니다.
    
    ━━━━━━━━━━━━━━━━━━━━
    
    1. 수집하는 정보
    
    • 마이크 접근 (선택)
    음성 검색 기능 사용 시에만 마이크에 접근합니다. 음성 데이터는 Apple의 Speech Recognition 서비스를 통해 기기에서 처리되며, 당사 서버에 저장되지 않습니다.
    
    • AI 질문 내용
    AI 도우미(가말리엘) 기능 사용 시, 질문 내용이 OpenAI 서버로 전송됩니다. 이 데이터는 답변 생성에만 사용됩니다.
    
    • 앱 사용 데이터 (로컬 저장)
    - 읽기 진행 상황
    - 즐겨찾기 구절 및 노트
    - 앱 설정 (언어, 번역본 선택 등)
    
    이 데이터는 오직 사용자 기기에만 저장되며, 외부 서버로 전송되지 않습니다.
    
    ━━━━━━━━━━━━━━━━━━━━
    
    2. 제3자 서비스
    
    • OpenAI API
    AI 도우미 및 음성 낭독 기능에 OpenAI의 서비스를 사용합니다.
    OpenAI 개인정보 처리방침: https://openai.com/privacy
    
    • 성경 텍스트 API
    성경 본문을 제공하기 위해 외부 API를 사용합니다. 이 과정에서 개인 식별 정보는 전송되지 않습니다.
    
    ━━━━━━━━━━━━━━━━━━━━
    
    3. 데이터 저장 및 보안
    
    • 사용자의 개인 데이터(즐겨찾기, 노트, 설정)는 기기에만 저장됩니다.
    • 별도의 회원가입이나 계정 생성이 없습니다.
    • 당사는 사용자의 개인정보를 판매하거나 광고 목적으로 사용하지 않습니다.
    
    ━━━━━━━━━━━━━━━━━━━━
    
    4. 사용자의 권리
    
    • 앱 설정에서 언제든지 데이터를 삭제할 수 있습니다.
    • 앱을 삭제하면 모든 로컬 데이터가 삭제됩니다.
    
    ━━━━━━━━━━━━━━━━━━━━
    
    5. 문의
    
    개인정보 처리와 관련한 문의사항은 아래 이메일로 연락해 주세요:
    jiwoong.net@gmail.com
    
    ━━━━━━━━━━━━━━━━━━━━
    
    본 개인정보 처리방침은 변경될 수 있으며, 중요한 변경 시 앱 내 공지를 통해 알려드립니다.
    """
    
    private static let privacyPolicyEN = """
    Privacy Policy
    
    Last Updated: January 2025
    
    Selah values your privacy and is committed to protecting your personal information in accordance with applicable laws.
    
    ━━━━━━━━━━━━━━━━━━━━
    
    1. Information We Collect
    
    • Microphone Access (Optional)
    We access your microphone only when you use voice search. Voice data is processed on-device through Apple's Speech Recognition and is not stored on our servers.
    
    • AI Queries
    When using the AI assistant feature, your questions are sent to OpenAI's servers to generate responses. This data is used solely for providing answers.
    
    • App Usage Data (Stored Locally)
    - Reading progress
    - Favorite verses and notes
    - App settings (language, translation preferences)
    
    This data is stored only on your device and is never transmitted to external servers.
    
    ━━━━━━━━━━━━━━━━━━━━
    
    2. Third-Party Services
    
    • OpenAI API
    We use OpenAI's services for the AI assistant and text-to-speech features.
    OpenAI Privacy Policy: https://openai.com/privacy
    
    • Bible Text APIs
    We use external APIs to provide Bible text. No personally identifiable information is transmitted in this process.
    
    ━━━━━━━━━━━━━━━━━━━━
    
    3. Data Storage & Security
    
    • Your personal data (favorites, notes, settings) is stored only on your device.
    • There is no account registration or sign-up required.
    • We do not sell your data or use it for advertising purposes.
    
    ━━━━━━━━━━━━━━━━━━━━
    
    4. Your Rights
    
    • You can delete your data at any time through the app settings.
    • Deleting the app removes all local data.
    
    ━━━━━━━━━━━━━━━━━━━━
    
    5. Contact Us
    
    For privacy-related inquiries, please contact:
    jiwoong.net@gmail.com
    
    ━━━━━━━━━━━━━━━━━━━━
    
    This privacy policy may be updated. Significant changes will be communicated through in-app notifications.
    """
    
    // MARK: - Terms of Service
    
    static func termsOfService(isKorean: Bool) -> String {
        isKorean ? termsOfServiceKR : termsOfServiceEN
    }
    
    private static let termsOfServiceKR = """
    이용약관
    
    최종 업데이트: 2025년 1월
    
    셀라(Selah) 앱을 이용해 주셔서 감사합니다. 본 앱을 사용함으로써 아래의 이용약관에 동의하는 것으로 간주됩니다.
    
    ━━━━━━━━━━━━━━━━━━━━
    
    1. 서비스 개요
    
    셀라는 성경 읽기와 묵상을 돕기 위한 앱입니다. 주요 기능은 다음과 같습니다:
    • 성경 본문 열람
    • AI 기반 성경 질의응답
    • 음성 검색 및 TTS 낭독
    • 즐겨찾기 및 노트 기능
    
    ━━━━━━━━━━━━━━━━━━━━
    
    2. 사용자의 의무
    
    • 앱을 불법적인 목적으로 사용하지 않습니다.
    • AI 기능을 악용하여 부적절한 콘텐츠를 생성하지 않습니다.
    • 앱의 정상적인 운영을 방해하지 않습니다.
    
    ━━━━━━━━━━━━━━━━━━━━
    
    3. AI 서비스 관련
    
    • AI 도우미가 제공하는 답변은 참고용이며, 공식적인 신학적 조언을 대체하지 않습니다.
    • AI 응답의 정확성을 보장하지 않으며, 중요한 결정에는 전문가와 상담하시기 바랍니다.
    • AI 서비스는 OpenAI의 이용약관을 따릅니다.
    
    ━━━━━━━━━━━━━━━━━━━━
    
    4. 콘텐츠 저작권
    
    • 성경 본문의 저작권은 해당 번역 출판사에 있습니다.
    • 앱 디자인 및 기능에 대한 권리는 개발자에게 있습니다.
    • 사용자가 작성한 노트는 사용자에게 귀속됩니다.
    
    ━━━━━━━━━━━━━━━━━━━━
    
    5. 면책조항
    
    • 앱 사용 중 발생하는 데이터 손실에 대해 책임지지 않습니다.
    • 서비스 중단이나 변경에 대해 사전 통지 없이 진행될 수 있습니다.
    • 제3자 API(성경 텍스트, OpenAI)의 서비스 변경에 따른 기능 제한이 발생할 수 있습니다.
    
    ━━━━━━━━━━━━━━━━━━━━
    
    6. 서비스 변경 및 종료
    
    • 서비스 내용은 사전 통지 없이 변경될 수 있습니다.
    • 필요한 경우 서비스를 종료할 수 있습니다.
    
    ━━━━━━━━━━━━━━━━━━━━
    
    7. 문의
    
    이용약관에 대한 문의:
    jiwoong.net@gmail.com
    """
    
    private static let termsOfServiceEN = """
    Terms of Service
    
    Last Updated: January 2025
    
    Thank you for using Selah. By using this app, you agree to the following terms of service.
    
    ━━━━━━━━━━━━━━━━━━━━
    
    1. Service Overview
    
    Selah is an app designed to help with Bible reading and meditation. Key features include:
    • Bible text reading
    • AI-powered Bible Q&A
    • Voice search and TTS narration
    • Favorites and notes
    
    ━━━━━━━━━━━━━━━━━━━━
    
    2. User Responsibilities
    
    • Do not use the app for illegal purposes.
    • Do not misuse AI features to generate inappropriate content.
    • Do not interfere with the normal operation of the app.
    
    ━━━━━━━━━━━━━━━━━━━━
    
    3. AI Service Terms
    
    • Answers from the AI assistant are for reference only and do not replace official theological advice.
    • We do not guarantee the accuracy of AI responses. Please consult experts for important decisions.
    • AI services are subject to OpenAI's terms of use.
    
    ━━━━━━━━━━━━━━━━━━━━
    
    4. Content Copyright
    
    • Bible text copyrights belong to their respective translation publishers.
    • App design and functionality rights belong to the developer.
    • Notes created by users belong to the users.
    
    ━━━━━━━━━━━━━━━━━━━━
    
    5. Disclaimer
    
    • We are not responsible for data loss during app usage.
    • Service interruptions or changes may occur without prior notice.
    • Features may be limited due to changes in third-party APIs (Bible text, OpenAI).
    
    ━━━━━━━━━━━━━━━━━━━━
    
    6. Service Modifications
    
    • Service content may change without prior notice.
    • The service may be terminated if necessary.
    
    ━━━━━━━━━━━━━━━━━━━━
    
    7. Contact
    
    For inquiries about terms of service:
    jiwoong.net@gmail.com
    """
    
    // MARK: - AI Disclosure
    
    static func aiDisclosure(isKorean: Bool) -> String {
        isKorean ? aiDisclosureKR : aiDisclosureEN
    }
    
    private static let aiDisclosureKR = """
    AI 도우미 정보
    
    셀라의 AI 기능에 대해 안내드립니다.
    
    ━━━━━━━━━━━━━━━━━━━━
    
    🤖 사용 기술
    
    • AI 모델: OpenAI GPT-4o
    • 음성 합성: OpenAI TTS
    • 음성 인식: Apple Speech Recognition
    
    ━━━━━━━━━━━━━━━━━━━━
    
    📖 AI의 원칙
    
    셀라의 AI 도우미는 다음 원칙을 따릅니다:
    
    1. 성경 중심
    모든 답변은 성경에 근거합니다.
    
    2. 정통 기독교 교리 준수
    니케아 신조에 기반한 정통 기독교 교리를 따르며, 삼위일체, 그리스도의 신성과 인성, 은혜로 인한 구원 등 핵심 교리를 존중합니다.
    
    3. 교단적 중립
    특정 교단의 관점만을 강요하지 않으며, 다양한 기독교 전통을 존중합니다.
    
    4. 성경 구절 인용
    답변 시 관련 성경 구절을 명확히 인용합니다.
    
    ━━━━━━━━━━━━━━━━━━━━
    
    ⚠️ AI의 한계
    
    AI 도우미를 사용할 때 다음 사항을 유의해 주세요:
    
    • 참고용입니다
    AI가 제공하는 정보는 참고 목적이며, 공식적인 신학적 가르침을 대체하지 않습니다.
    
    • 오류 가능성
    AI는 실수할 수 있습니다. 중요한 내용은 성경 원문과 대조해 확인하세요.
    
    • 전문가 상담 권장
    중요한 신학적 결정이나 영적 상담이 필요한 경우, 목회자나 신학자와 상담하시기 바랍니다.
    
    • 최신 정보 제한
    AI는 학습 데이터 기준으로 응답하며, 최신 신학 논의를 반영하지 못할 수 있습니다.
    
    ━━━━━━━━━━━━━━━━━━━━
    
    🔒 데이터 처리
    
    • AI에게 보내는 질문은 OpenAI 서버에서 처리됩니다.
    • 대화 내용은 앱 내에 저장되지 않습니다.
    • OpenAI의 데이터 처리에 대한 자세한 내용:
      https://openai.com/privacy
    
    ━━━━━━━━━━━━━━━━━━━━
    
    이 기능에 대한 문의:
    jiwoong.net@gmail.com
    """
    
    private static let aiDisclosureEN = """
    AI Assistant Information
    
    Learn about Selah's AI features.
    
    ━━━━━━━━━━━━━━━━━━━━
    
    🤖 Technology Used
    
    • AI Model: OpenAI GPT-4o
    • Text-to-Speech: OpenAI TTS
    • Voice Recognition: Apple Speech Recognition
    
    ━━━━━━━━━━━━━━━━━━━━
    
    📖 AI Principles
    
    Selah's AI assistant follows these principles:
    
    1. Scripture-Centered
    All answers are grounded in the Bible.
    
    2. Orthodox Christian Doctrine
    Adheres to orthodox Christian doctrine based on the Nicene Creed, respecting core doctrines such as the Trinity, the deity and humanity of Christ, and salvation by grace.
    
    3. Denominational Neutrality
    Does not impose a single denominational perspective and respects diverse Christian traditions.
    
    4. Scripture Citation
    Clearly cites relevant Bible verses in responses.
    
    ━━━━━━━━━━━━━━━━━━━━
    
    ⚠️ AI Limitations
    
    Please note the following when using the AI assistant:
    
    • For Reference Only
    Information provided by AI is for reference purposes and does not replace official theological teaching.
    
    • Potential for Errors
    AI can make mistakes. Please verify important content against the original Scripture.
    
    • Professional Consultation Recommended
    For important theological decisions or spiritual counseling, please consult with pastors or theologians.
    
    • Limited Current Information
    AI responds based on training data and may not reflect the latest theological discussions.
    
    ━━━━━━━━━━━━━━━━━━━━
    
    🔒 Data Processing
    
    • Questions sent to AI are processed on OpenAI servers.
    • Conversation content is not stored within the app.
    • For details on OpenAI's data processing:
      https://openai.com/privacy
    
    ━━━━━━━━━━━━━━━━━━━━
    
    For inquiries about this feature:
    jiwoong.net@gmail.com
    """
    
    // MARK: - Acknowledgments (Optional - for future use)
    
    static func acknowledgments(isKorean: Bool) -> String {
        isKorean ? acknowledgmentsKR : acknowledgmentsEN
    }
    
    private static let acknowledgmentsKR = """
    감사의 말
    
    셀라는 다음의 오픈소스 프로젝트와 서비스를 사용합니다:
    
    • OpenAI API - AI 대화 및 음성 합성
    • Bible API - 성경 텍스트 데이터
    • Spectral Font - 영문 세리프 폰트
    • Noto Serif/Sans KR - 한글 폰트
    
    ━━━━━━━━━━━━━━━━━━━━
    
    성경 번역 저작권
    
    각 성경 번역본의 저작권은 해당 출판사에 있습니다.
    """
    
    private static let acknowledgmentsEN = """
    Acknowledgments
    
    Selah uses the following open-source projects and services:
    
    • OpenAI API - AI conversation and text-to-speech
    • Bible API - Scripture text data
    • Spectral Font - English serif typography
    • Noto Serif/Sans KR - Korean typography
    
    ━━━━━━━━━━━━━━━━━━━━
    
    Bible Translation Copyright
    
    Copyrights for each Bible translation belong to their respective publishers.
    """
}
