#!/usr/bin/env python3
"""
Generate a unique app icon for Beacon of New Beginnings NGO app
Creates a beacon/lighthouse design with healing colors
"""

try:
    from PIL import Image, ImageDraw, ImageFont
    print("PIL (Pillow) is available")
except ImportError:
    print("Installing Pillow...")
    import subprocess
    import sys
    subprocess.check_call([sys.executable, "-m", "pip", "install", "Pillow"])
    from PIL import Image, ImageDraw, ImageFont

import os

def create_app_icon():
    # Icon sizes for iOS and Android
    sizes = [
        # iOS sizes
        (20, "ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-20x20@1x.png"),
        (40, "ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-20x20@2x.png"),
        (60, "ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-20x20@3x.png"),
        (29, "ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-29x29@1x.png"),
        (58, "ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-29x29@2x.png"),
        (87, "ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-29x29@3x.png"),
        (40, "ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-40x40@1x.png"),
        (80, "ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-40x40@2x.png"),
        (120, "ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-40x40@3x.png"),
        (120, "ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-60x60@2x.png"),
        (180, "ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-60x60@3x.png"),
        (76, "ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-76x76@1x.png"),
        (152, "ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-76x76@2x.png"),
        (167, "ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-83.5x83.5@2x.png"),
        (1024, "ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-1024x1024@1x.png"),
        
        # Android sizes
        (48, "android/app/src/main/res/mipmap-mdpi/ic_launcher.png"),
        (72, "android/app/src/main/res/mipmap-hdpi/ic_launcher.png"),
        (96, "android/app/src/main/res/mipmap-xhdpi/ic_launcher.png"),
        (144, "android/app/src/main/res/mipmap-xxhdpi/ic_launcher.png"),
        (192, "android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png"),
    ]
    
    # Create base design at high resolution
    base_size = 1024
    
    for size, path in sizes:
        create_icon_variant(size, path)
        print(f"Created icon: {path}")

def create_icon_variant(size, output_path):
    # Create image with solid background (no transparency for App Store)
    img = Image.new('RGB', (size, size), (0, 121, 107))  # Solid teal background
    draw = ImageDraw.Draw(img)
    
    # Colors inspired by hope, healing, and empowerment
    bg_color = (0, 121, 107)  # Teal - same as app primary color
    beacon_color = (255, 193, 7)  # Amber - represents light/hope
    light_rays = (255, 235, 59)  # Light yellow - represents healing
    support_color = (76, 175, 80)  # Green - represents growth
    
    # Background is already solid teal - no need for rounded rectangle
    # iOS automatically applies rounded corners
    
    # Calculate proportions
    center_x, center_y = size // 2, size // 2
    beacon_height = size * 0.6
    beacon_width = size * 0.15
    
    # Draw beacon/lighthouse structure
    beacon_base_y = center_y + beacon_height // 3
    beacon_top_y = center_y - beacon_height // 3
    
    # Beacon tower (lighthouse)
    tower_left = center_x - beacon_width // 2
    tower_right = center_x + beacon_width // 2
    tower_top = beacon_top_y + size * 0.05
    
    draw.rectangle(
        [tower_left, tower_top, tower_right, beacon_base_y],
        fill=(255, 255, 255)  # White tower
    )
    
    # Beacon light (circular at top)
    light_radius = beacon_width * 0.8
    light_center_y = tower_top - light_radius // 2
    
    draw.ellipse(
        [center_x - light_radius, light_center_y - light_radius,
         center_x + light_radius, light_center_y + light_radius],
        fill=beacon_color
    )
    
    # Light rays emanating from beacon
    ray_length = size * 0.25
    num_rays = 8
    ray_width = max(2, size // 100)
    
    for i in range(num_rays):
        angle = (i * 360 / num_rays) * 3.14159 / 180
        start_x = center_x + (light_radius * 1.2) * (angle < 3.14159 and -0.5 or 0.5)
        start_y = light_center_y + (light_radius * 1.2) * (angle < 3.14159 and 0.3 or -0.3)
        
        if i % 2 == 0:  # Alternate ray lengths for dynamic effect
            end_x = start_x + ray_length * (1 if angle < 3.14159 else -1)
            end_y = start_y - ray_length * 0.3
            
            # Draw light ray
            draw.line(
                [start_x, start_y, end_x, end_y],
                fill=light_rays,
                width=ray_width
            )
    
    # Support symbols (hands/hearts) around the base
    symbol_y = beacon_base_y + size * 0.08
    symbol_size = size * 0.08
    
    # Left support symbol (representing community)
    left_x = center_x - size * 0.25
    draw.ellipse(
        [left_x - symbol_size//2, symbol_y - symbol_size//2,
         left_x + symbol_size//2, symbol_y + symbol_size//2],
        fill=support_color
    )
    
    # Right support symbol
    right_x = center_x + size * 0.25
    draw.ellipse(
        [right_x - symbol_size//2, symbol_y - symbol_size//2,
         right_x + symbol_size//2, symbol_y + symbol_size//2],
        fill=support_color
    )
    
    # Add small heart in center bottom (symbol of care)
    heart_y = beacon_base_y + size * 0.15
    heart_size = size * 0.06
    
    # Simple heart shape using two circles and a triangle
    heart_left = center_x - heart_size//3
    heart_right = center_x + heart_size//3
    heart_top = heart_y - heart_size//3
    
    # Heart circles
    draw.ellipse(
        [heart_left - heart_size//4, heart_top - heart_size//4,
         heart_left + heart_size//4, heart_top + heart_size//4],
        fill=(255, 87, 87)  # Red heart color
    )
    draw.ellipse(
        [heart_right - heart_size//4, heart_top - heart_size//4,
         heart_right + heart_size//4, heart_top + heart_size//4],
        fill=(255, 87, 87)
    )
    
    # Heart bottom point
    draw.polygon(
        [center_x, heart_y + heart_size//3,
         heart_left, heart_top,
         heart_right, heart_top],
        fill=(255, 87, 87)
    )
    
    # Ensure output directory exists
    os.makedirs(os.path.dirname(output_path), exist_ok=True)
    
    # Save the icon
    img.save(output_path, 'PNG')

if __name__ == "__main__":
    print("Creating unique app icon for Beacon of New Beginnings...")
    create_app_icon()
    print("App icon creation completed!")
    print("\nIcon symbolism:")
    print("🏮 Beacon/Lighthouse: Guidance and hope in darkness")
    print("💛 Light rays: Healing and empowerment radiating outward") 
    print("💚 Support circles: Community and mutual aid")
    print("❤️ Heart: Care, compassion, and love")
    print("🎨 Teal background: Trust, healing, and emotional balance")