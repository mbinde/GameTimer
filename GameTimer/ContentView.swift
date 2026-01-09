import SwiftUI
import AVFoundation

struct ContentView: View {
    @State private var timerState: TimerState = .ready
    @State private var remainingSeconds: Int = 600 // 10 minutes
    @State private var timer: Timer?
    @State private var audioPlayer: AVAudioPlayer?
    @State private var audioDelegate: AudioDelegate?

    enum TimerState {
        case ready
        case starting // playing start sound
        case running
        case paused
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
            } else {
                Text(timeString)
                    .font(.custom("Digital-7Mono", size: 120))
                    .foregroundColor(.green)
                    .onTapGesture {
                        togglePause()
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
        playSound(named: "end") {
            self.timerState = .ready
            self.remainingSeconds = 600
        }
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
