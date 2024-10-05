# Coffee Machine Ordering Script

# Function to display menu
function Show-Menu {
    Write-Host "1. Order Coffee Machine"
    Write-Host "2. Check Order Status"
    Write-Host "3. Exit"
}

# Function to order coffee machine
function Order-CoffeeMachine {
    param (
        [string]$model,
        [int]$quantity
    )
    Write-Host "Ordering $quantity of $model coffee machine(s)..."
    # Add your ordering logic here
}

# Function to check order status
function Check-OrderStatus {
    Write-Host "Checking order status..."
    # Add your status checking logic here
}

# Main script logic
do {
    Show-Menu
    $choice = Read-Host "Enter your choice"
    switch ($choice) {
        1 {
            $model = Read-Host "Enter coffee machine model"
            $quantity = Read-Host "Enter quantity"
            Order-CoffeeMachine -model $model -quantity $quantity
        }
        2 {
            Check-OrderStatus
        }
        3 {
            Write-Host "Exiting..."
        }
        default {
            Write-Host "Invalid choice, please try again."
        }
    }
} while ($choice -ne 3)
