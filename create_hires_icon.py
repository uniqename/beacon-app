#!/usr/bin/env python3
"""
Create hi-res icon for Google Play Store from launcher icon
"""

from PIL import Image
import os

def create_hires_icon():
    """Create 512x512 hi-res icon from the launcher icon"""
    
    # Load the largest launcher icon
    launcher_icon_path = "/Users/enamegyir/Documents/Projects/beacon-ngo-app/ngo_support_app/android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png"
    output_path = "/Users/enamegyir/Desktop/beacon_hires_icon_512x512.png"
    
    # Load and resize to 512x512 for Google Play Store
    icon = Image.open(launcher_icon_path)
    hires_icon = icon.resize((512, 512), Image.Resampling.LANCZOS)
    
    # Save the hi-res icon
    hires_icon.save(output_path, 'PNG', quality=95)
    print(f"✅ Hi-res icon created: {output_path}")
    print("Upload this file to Google Play Console → Store Listing → Graphics → Hi-res icon")

if __name__ == "__main__":
    create_hires_icon()