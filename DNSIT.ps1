Add-Type -TypeDefinition @"
using System;
using System.Windows.Forms;

public class DnsChanger : Form
{
    private TextBox primaryDns;
    private TextBox secondaryDns;
    private Button applyButton;
    private Button resetButton;
    
    public DnsChanger()
    {
        this.Text = "DNS Changer";
        this.Size = new System.Drawing.Size(300, 200);

        Label label1 = new Label() { Text = "Primary DNS:", Left = 10, Top = 20 };
        primaryDns = new TextBox() { Left = 100, Top = 20, Width = 150 };
        
        Label label2 = new Label() { Text = "Secondary DNS:", Left = 10, Top = 50 };
        secondaryDns = new TextBox() { Left = 100, Top = 50, Width = 150 };

        applyButton = new Button() { Text = "Apply", Left = 30, Top = 90, Width = 100 };
        applyButton.Click += (sender, e) => ApplyDns();
        
        resetButton = new Button() { Text = "Reset", Left = 150, Top = 90, Width = 100 };
        resetButton.Click += (sender, e) => ResetDns();

        this.Controls.Add(label1);
        this.Controls.Add(primaryDns);
        this.Controls.Add(label2);
        this.Controls.Add(secondaryDns);
        this.Controls.Add(applyButton);
        this.Controls.Add(resetButton);
    }

    private void ApplyDns()
    {
        string primary = primaryDns.Text;
        string secondary = secondaryDns.Text;
        
        string script = $"""
            $adapter = Get-NetAdapter | Where-Object { $_.Status -eq 'Up' }
            Set-DnsClientServerAddress -InterfaceIndex $adapter.ifIndex -ServerAddresses ('{primary}', '{secondary}')
        """;
        
        System.Diagnostics.Process.Start("powershell", "-Command " + script);
        MessageBox.Show("DNS changed successfully!", "Success", MessageBoxButtons.OK, MessageBoxIcon.Information);
    }

    private void ResetDns()
    {
        string script = "Get-NetAdapter | Where-Object { $_.Status -eq 'Up' } | Set-DnsClientServerAddress -ResetServerAddresses";
        System.Diagnostics.Process.Start("powershell", "-Command " + script);
        MessageBox.Show("DNS reset to default!", "Success", MessageBoxButtons.OK, MessageBoxIcon.Information);
    }
}

public class Program
{
    [STAThread]
    public static void Main()
    {
        Application.EnableVisualStyles();
        Application.Run(new DnsChanger());
    }
}
"@ -Language CSharp

[Program]::Main()
