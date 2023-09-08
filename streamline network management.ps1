Add-Type -AssemblyName System.Windows.Forms
Add-Type -TypeDefinition @"
    using System;
    using System.Windows.Forms;

    public class NetworkForm : Form
    {
        private TextBox txtIpAddress;
        private Button btnPing;

        public NetworkForm()
        {
            this.Text = "Network Tools";
            this.Width = 300;
            this.Height = 150;

            txtIpAddress = new TextBox();
            txtIpAddress.Location = new System.Drawing.Point(20, 20);
            txtIpAddress.Width = 200;
            this.Controls.Add(txtIpAddress);

            btnPing = new Button();
            btnPing.Location = new System.Drawing.Point(20, 60);
            btnPing.Text = "Ping";
            btnPing.Click += new EventHandler(btnPing_Click);
            this.Controls.Add(btnPing);
        }

        private void btnPing_Click(object sender, EventArgs e)
        {
            string ipAddress = txtIpAddress.Text;
            if (!string.IsNullOrEmpty(ipAddress))
            {
                // You can replace this with your network-related code (e.g., ping).
                MessageBox.Show($"Pinging {ipAddress}...");
            }
            else
            {
                MessageBox.Show("Please enter an IP address or hostname.");
            }
        }

        [STAThread]
        public static void Main()
        {
            Application.EnableVisualStyles();
            Application.Run(new NetworkForm());
        }
    }
"@

[NetworkForm]::Main()
