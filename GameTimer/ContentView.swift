import SwiftUI
import AVFoundation

struct ContentView: View {
    @State private var timerState: TimerState = .ready
    @State private var remainingSeconds: Int = 600 // 10 minutes
    @State private var timer: Timer?
    @State private var audioPlayer: AVAudioPlayer?
    @State private var audioDelegate: AudioDelegate?
    @State private var flashVisible: Bool = true
    @State private var flashTimer: Timer?

    enum TimerState {
        case ready
        case starting // playing start sound
        case running
        case paused
        case finished // playing end sound, 0:00 flashing
    }

    class AudioDelegate: NSObject, AVAudioPlayerDelegate {
        var onFinished: () -> Void

        init(onFinished: @escaping () -> Void) {
            self.onFinished = onFinished
        }

        func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
            onFinished()
        }
    }

    var timeString: String {
        let minutes = remainingSeconds / 60
        let seconds = remainingSeconds % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    var body: some View {
        ZStack {
            Color.black
                .ignoresSafeArea()

            if timerState == .ready {
                Button(action: startTimer) {
                    Text("START")
                        .font(.custom("Digital-7Mono", size: 80))
                        .foregroundColor(.green)
                }
            } else if timerState == .finished {
                Text(timeString)
                    .font(.custom("Digital-7Mono", size: 120))
                    .foregroundColor(.green)
                    .opacity(flashVisible ? 1.0 : 0.0)
                    .onTapGesture {
                        resetToStart()
                    }
            } else {
                Text(timeString)
                    .font(.custom("Digital-7Mono", size: 120))
                    .foregroundColor(.green)
                    .onTapGesture {
                        togglePause()
                    }
            }

            // Reset button in top-right corner when paused
            if timerState == .paused {
                VStack {
                    HStack {
                        Spacer()
                        Button(action: resetToStart) {
                            Text("X")
                                .font(.system(size: 24, weight: .bold))
                                .foregroundColor(.green.opacity(0.6))
                                .frame(width: 44, height: 44)
                        }
                        .padding(.trailing, 20)
                        .padding(.top, 20)
                    }
                    Spacer()
                }
            }
        }
    }

    func startTimer() {
        remainingSeconds = 600
        timerState = .starting

        playSound(named: "start") {
            self.timerState = .running
            self.timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
                if self.remainingSeconds > 0 {
                    self.remainingSeconds -= 1
                } else {
                    self.timerFinished()
                }
            }
        }
    }

    func togglePause() {
        if timerState == .running {
            timer?.invalidate()
            timerState = .paused
        } else if timerState == .paused {
            timerState = .running
            timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
                if remainingSeconds > 0 {
                    remainingSeconds -= 1
                } else {
                    timerFinished()
                }
            }
        }
    }

    func timerFinished() {
        timer?.invalidate()
        timerState = .finished
        flashVisible = true

        // Start flashing 0:00
        flashTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { _ in
            flashVisible.toggle()
        }

        playSound(named: "end") {}
    }

    func resetToStart() {
        timer?.invalidate()
        flashTimer?.invalidate()
        audioPlayer?.stop()
        timerState = .ready
        remainingSeconds = 600
        flashVisible = true
    }

    func playSound(named name: String, onFinished: @escaping () -> Void = {}) {
        if let path = Bundle.main.path(forResource: name, ofType: "mp3") {
            let url = URL(fileURLWithPath: path)
            do {
                audioPlayer = try AVAudioPlayer(contentsOf: url)
                audioDelegate = AudioDelegate(onFinished: onFinished)
                audioPlayer?.delegate = audioDelegate
                audioPlayer?.play()
            } catch {
                print("Could not play sound: \(error)")
                onFinished()
            }
        } else {
            onFinished()
        }
    }
}

#Preview {
    ContentView()
}
