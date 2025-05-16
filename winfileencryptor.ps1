Add-Type -TypeDefinition @"
using System;
using System.IO;
using System.Security.Cryptography;
using System.Text;
using System.Windows.Forms;

public class FileEncryptor {
    private static readonly string Key = "your-32-byte-encryption-key"; // Use a strong key

    public static void EncryptFile(string inputFile, string outputFile) {
        using (Aes aes = Aes.Create()) {
            aes.Key = Encoding.UTF8.GetBytes(Key);
            aes.GenerateIV();
            using (FileStream fs = new FileStream(outputFile, FileMode.Create)) {
                fs.Write(aes.IV, 0, aes.IV.Length);
                using (CryptoStream cs = new CryptoStream(fs, aes.CreateEncryptor(), CryptoStreamMode.Write))
                using (FileStream fsInput = new FileStream(inputFile, FileMode.Open)) {
                    fsInput.CopyTo(cs);
                }
            }
        }
    }

    public static void DecryptFile(string inputFile, string outputFile) {
        using (FileStream fsInput = new FileStream(inputFile, FileMode.Open))
        using (Aes aes = Aes.Create()) {
            byte[] iv = new byte[aes.IV.Length];
            fsInput.Read(iv, 0, iv.Length);
            aes.Key = Encoding.UTF8.GetBytes(Key);
            aes.IV = iv;
            using (CryptoStream cs = new CryptoStream(fsInput, aes.CreateDecryptor(), CryptoStreamMode.Read))
            using (FileStream fsOutput = new FileStream(outputFile, FileMode.Create)) {
                cs.CopyTo(fsOutput);
            }
        }
    }
}

public class EncryptorGUI : Form {
    private Button encryptButton;
    private Button decryptButton;
    private TextBox filePathBox;
    private OpenFileDialog openFileDialog;

    public EncryptorGUI() {
        this.Text = "File Encryptor";
        this.Size = new System.Drawing.Size(400, 200);

        filePathBox = new TextBox { Left = 20, Top = 20, Width = 260 };
        encryptButton = new Button { Text = "Encrypt", Left = 20, Top = 60, Width = 100 };
        decryptButton = new Button { Text = "Decrypt", Left = 130, Top = 60, Width = 100 };
        openFileDialog = new OpenFileDialog();

        encryptButton.Click += (sender, e) => {
            if (File.Exists(filePathBox.Text)) {
                FileEncryptor.EncryptFile(filePathBox.Text, filePathBox.Text + ".enc");
                MessageBox.Show("File encrypted successfully!");
            }
        };

        decryptButton.Click += (sender, e) => {
            if (File.Exists(filePathBox.Text)) {
                FileEncryptor.DecryptFile(filePathBox.Text, filePathBox.Text.Replace(".enc", ".dec"));
                MessageBox.Show("File decrypted successfully!");
            }
        };

        this.Controls.Add(filePathBox);
        this.Controls.Add(encryptButton);
        this.Controls.Add(decryptButton);
    }
}

public class Program {
    [STAThread]
    public static void Main() {
        Application.Run(new EncryptorGUI());
    }
}
"@

[Program]::Main()
