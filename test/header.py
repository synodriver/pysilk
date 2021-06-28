from silk import Transcoder

tr = Transcoder()
data=tr.encode_file("Alarm01.wav", "output.silk")
print(data)
