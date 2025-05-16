Add-Type -TypeDefinition @"
using System;
using System.Speech.Synthesis;
using System.Windows.Forms;

public class TextToSpeechApp
{
    private SpeechSynthesizer synth = new SpeechSynthesizer();
    private Form form = new Form();
    private TextBox textBox = new TextBox();
    private Button speakButton = new Button();

    public TextToSpeechApp()
    {
        form.Text = "AI Text-to-Speech (Greek)";
        form.Size = new System.Drawing.Size(400, 200);

        textBox.Size = new System.Drawing.Size(250, 30);
        textBox.Location = new System.Drawing.Point(50, 40);
        form.Controls.Add(textBox);

        speakButton.Text = "Speak";
        speakButton.Location = new System.Drawing.Point(50, 80);
        speakButton.Click += new EventHandler(SpeakText);
        form.Controls.Add(speakButton);

        synth.SelectVoice("Microsoft Stefanos Desktop"); // Ensure the Greek voice is available
    }

    private void SpeakText(object sender, EventArgs e)
    {
        synth.Speak(textBox.Text);
    }

    public void Run()
    {
        Application.Run(form);
    }
}
"@

$ttsApp = New-Object TextToSpeechApp
$ttsApp.Run()
