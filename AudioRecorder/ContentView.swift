//
//  ContentView.swift
//  AudioRecorder
//
//  Created by Алексей on 13.12.2024.
//
import SwiftUI
import AVFoundation
import CoreData

struct ContentView: View {
    @StateObject private var audioRecorder = AudioRecorder()
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \RecordsEntity.date, ascending: false)]
    ) var recordings: FetchedResults<RecordsEntity>

    var body: some View {
        NavigationView {
            VStack {
                List {
                    ForEach(recordings) { recording in
                        HStack {
                            Text(audioRecorder.formatDateTime(recording.date ?? Date()))
                                .foregroundStyle(Color.red)
                            Spacer()
                            Button(action: {
                                audioRecorder.playRecording(named: recording.name ?? "")
                            }) {
                                Image(systemName: "play.circle")
                                    .foregroundStyle(Color.green)
                                    .frame(width: 35, height: 35)
                            }
                        }
                    }
                    .onDelete(perform: deleteRecording)
                }
                
                VStack {
                    if audioRecorder.isRecording {
                        AudioVisualizerView(audioLevel: $audioRecorder.audioLevel)
                            .frame(height: 100)
                            .padding()
                    }
                    Button(action: {
                        if audioRecorder.isRecording {
                            audioRecorder.stopRecording()
                        } else {
                            audioRecorder.startRecording()
                        }
                    }) {
                        Text(audioRecorder.isRecording ? "Stop Recording" : "Start Recording")
                            .padding()
                            .background(audioRecorder.isRecording ? Color.red : Color.green)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                    .padding()
                }
            }
            .navigationTitle("Audio Recorder")
        }
    }

    private func deleteRecording(at offsets: IndexSet) {
        for index in offsets {
            let recording = recordings[index]
            audioRecorder.deleteRecording(named: recording.name ?? "")
            PersistenceController.shared.container.viewContext.delete(recording)
        }
        PersistenceController.shared.saveContext()
    }
}



#Preview {
    ContentView()
}
