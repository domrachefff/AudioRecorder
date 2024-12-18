//
//  AudioRecorder.swift
//  AudioRecorder
//
//  Created by Алексей on 13.12.2024.
//
import Foundation
import AVFoundation

class AudioRecorder: NSObject, ObservableObject, AVAudioRecorderDelegate {
    private var audioRecorder: AVAudioRecorder?
    private var audioPlayer: AVAudioPlayer?
    private let recordingsDirectory: URL
    private var timer: Timer?
    
    @Published var isRecording = false
    @Published var audioLevel: CGFloat = 0.0
    
    override init() {
        let fileManager = FileManager.default
        let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        recordingsDirectory = documentsURL.appendingPathComponent("Recordings")
        
        if !fileManager.fileExists(atPath: recordingsDirectory.path) {
            try? fileManager.createDirectory(at: recordingsDirectory, withIntermediateDirectories: true, attributes: nil)
        }
        
        audioRecorder?.isMeteringEnabled = true
    }
    
    func startRecording() {
        DispatchQueue.global(qos: .userInitiated).async {
            let filename = UUID().uuidString + ".m4a"
            let filePath = self.recordingsDirectory.appendingPathComponent(filename)
            
            let settings: [String: Any] = [
                AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
                AVSampleRateKey: 44100,
                AVNumberOfChannelsKey: 2,
                AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
            ]
            
            do {
                // Настройка аудиосессии для записи
                try AVAudioSession.sharedInstance().setCategory(
                    .playAndRecord,
                    mode: .default,
                    options: [.defaultToSpeaker, .allowBluetooth]
                )
                try AVAudioSession.sharedInstance().setActive(true)
                
                let recorder = try AVAudioRecorder(url: filePath, settings: settings)
                recorder.isMeteringEnabled = true
                recorder.record()
                
                DispatchQueue.main.async {
                    self.audioRecorder = recorder
                    self.isRecording = true
                    self.startAudioLevelUpdates()
                    
                    // Сохранение записи в Core Data
                    let newRecording = RecordsEntity(context: PersistenceController.shared.container.viewContext)
                    newRecording.name = filename
                    newRecording.date = Date()
                    PersistenceController.shared.saveContext()
                }
            } catch {
                print("Failed to start recording: \(error.localizedDescription)")
            }
        }
    }
    
    func stopRecording() {
        audioRecorder?.stop()
        isRecording = false
        stopAudioLevelUpdates()
    }
    
    private func startAudioLevelUpdates() {
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            guard let self = self, let recorder = self.audioRecorder else { return }
            recorder.updateMeters()
            
            // Получаем текущий уровень звука
            DispatchQueue.main.async {
                let power = recorder.averagePower(forChannel: 0)
                self.audioLevel = self.normalizeAudioLevel(power)
            }
        }
    }
    
    private func stopAudioLevelUpdates() {
        timer?.invalidate()
        timer = nil
    }
    
    private func normalizeAudioLevel(_ power: Float) -> CGFloat {
        // Нормализация уровня: -160 (тишина) до 0 (максимум)
        let minLevel: Float = -160
        return CGFloat((power - minLevel) / (-minLevel))
    }
    
    func playRecording(named filename: String) {
        let filePath = recordingsDirectory.appendingPathComponent(filename)
        
        guard FileManager.default.fileExists(atPath: filePath.path) else {
            print("File not found at path: \(filePath.path)")
            return
        }
        
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
            
            audioPlayer = try AVAudioPlayer(contentsOf: filePath)
            audioPlayer?.play()
        } catch {
            print("Failed to play recording: \(error.localizedDescription)")
        }
    }
    
    func deleteRecording(named filename: String) {
        let filePath = recordingsDirectory.appendingPathComponent(filename)
        do {
            try FileManager.default.removeItem(at: filePath)
        } catch {
            print("Failed to delete recording: \(error.localizedDescription)")
        }
    }
    
    func formatDateTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM dd, yyyy HH:mm" // Форматируем дату и время в одну строку
        
        return formatter.string(from: date)
    }
}
