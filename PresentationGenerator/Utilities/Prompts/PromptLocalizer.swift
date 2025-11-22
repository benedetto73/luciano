//
//  PromptLocalizer.swift
//  PresentationGenerator
//
//  Localized prompt templates for AI interactions
//

import Foundation

/// Manages localized AI prompts
enum PromptLocalizer {
    
    // MARK: - Content Analysis Prompts
    
    static var analyzeContentPrompt: String {
        switch LocalizationHelper.currentLanguage {
        case .english:
            return """
            Analyze the following educational content and extract the key teaching points.
            
            For each key point:
            - Identify the main concept or idea
            - Keep it concise (1-2 sentences)
            - Focus on what students should learn
            - Order by importance
            
            Return a JSON array of key points with this structure:
            {
              "keyPoints": [
                {
                  "content": "Key point description",
                  "order": 1
                }
              ]
            }
            
            Content to analyze:
            """
            
        case .italian:
            return """
            Analizza il seguente contenuto educativo ed estrai i punti chiave di insegnamento.
            
            Per ogni punto chiave:
            - Identifica il concetto o l'idea principale
            - Mantienilo conciso (1-2 frasi)
            - Concentrati su ciò che gli studenti dovrebbero imparare
            - Ordina per importanza
            
            Restituisci un array JSON di punti chiave con questa struttura:
            {
              "keyPoints": [
                {
                  "content": "Descrizione del punto chiave",
                  "order": 1
                }
              ]
            }
            
            Contenuto da analizzare:
            """
        }
    }
    
    // MARK: - Slide Generation Prompts
    
    static func generateSlidePrompt(for audience: Audience) -> String {
        switch LocalizationHelper.currentLanguage {
        case .english:
            let audienceDescription = audienceDescriptionEnglish(audience)
            return """
            Create a presentation slide based on the following key point.
            
            Target Audience: \(audienceDescription)
            
            Requirements:
            - Create a clear, engaging title
            - Provide 3-5 bullet points that explain the concept
            - Use language appropriate for the target audience
            - Keep bullet points concise and easy to understand
            - Include a brief description for potential visual elements
            
            Return JSON with this structure:
            {
              "title": "Slide title",
              "bullets": ["Bullet 1", "Bullet 2", "Bullet 3"],
              "visualDescription": "Description of suggested visual/image",
              "speakerNotes": "Additional context for the presenter"
            }
            
            Key point:
            """
            
        case .italian:
            let audienceDescription = audienceDescriptionItalian(audience)
            return """
            Crea una slide di presentazione basata sul seguente punto chiave.
            
            Pubblico di Destinazione: \(audienceDescription)
            
            Requisiti:
            - Crea un titolo chiaro e coinvolgente
            - Fornisci 3-5 punti elenco che spiegano il concetto
            - Usa un linguaggio appropriato per il pubblico di destinazione
            - Mantieni i punti elenco concisi e facili da capire
            - Includi una breve descrizione per eventuali elementi visivi
            
            Restituisci JSON con questa struttura:
            {
              "title": "Titolo della slide",
              "bullets": ["Punto 1", "Punto 2", "Punto 3"],
              "visualDescription": "Descrizione del visual/immagine suggerito",
              "speakerNotes": "Contesto aggiuntivo per il presentatore"
            }
            
            Punto chiave:
            """
        }
    }
    
    // MARK: - Image Generation Prompts
    
    static func imageGenerationPrompt(concept: String, audience: Audience) -> String {
        switch LocalizationHelper.currentLanguage {
        case .english:
            let style = imageStyleEnglish(for: audience)
            return """
            Create an educational illustration for: \(concept)
            
            Style: \(style)
            Requirements:
            - Clear, simple, easy to understand
            - Appropriate for \(audience.rawValue.lowercased()) audience
            - Professional quality
            - No text in the image
            """
            
        case .italian:
            let style = imageStyleItalian(for: audience)
            return """
            Crea un'illustrazione educativa per: \(concept)
            
            Stile: \(style)
            Requisiti:
            - Chiara, semplice, facile da capire
            - Appropriata per pubblico \(audienceNameItalian(audience))
            - Qualità professionale
            - Nessun testo nell'immagine
            """
        }
    }
    
    // MARK: - Helper Functions
    
    private static func audienceDescriptionEnglish(_ audience: Audience) -> String {
        switch audience {
        case .kids:
            return "Children (ages 6-12) - use simple language, fun examples, and engaging visuals"
        case .adults:
            return "Adults - use professional tone, detailed explanations, and sophisticated examples"
        }
    }
    
    private static func audienceDescriptionItalian(_ audience: Audience) -> String {
        switch audience {
        case .kids:
            return "Bambini (età 6-12) - usa linguaggio semplice, esempi divertenti e visual coinvolgenti"
        case .adults:
            return "Adulti - usa tono professionale, spiegazioni dettagliate ed esempi sofisticati"
        }
    }
    
    private static func imageStyleEnglish(for audience: Audience) -> String {
        switch audience {
        case .kids:
            return "Colorful, cartoonish, playful, child-friendly"
        case .adults:
            return "Professional, modern, clean, sophisticated"
        }
    }
    
    private static func imageStyleItalian(for audience: Audience) -> String {
        switch audience {
        case .kids:
            return "Colorato, cartone animato, giocoso, adatto ai bambini"
        case .adults:
            return "Professionale, moderno, pulito, sofisticato"
        }
    }
    
    private static func audienceNameItalian(_ audience: Audience) -> String {
        switch audience {
        case .kids: return "bambini"
        case .adults: return "adulti"
        }
    }
}
