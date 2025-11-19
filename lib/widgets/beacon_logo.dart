import 'package:flutter/material.dart';

class BeaconLogo extends StatelessWidget {
  final double size;
  final Color? color;
  final bool showText;
  final String? text;

  const BeaconLogo({
    super.key,
    this.size = 48.0,
    this.color,
    this.showText = false,
    this.text,
  });

  @override
  Widget build(BuildContext context) {
    final logoColor = color ?? Theme.of(context).primaryColor;
    
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Actual Beacon Logo
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.asset(
              'assets/images/beacon_logo.png',
              width: size,
              height: size,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                // Fallback to custom beacon icon if image fails to load
                return Container(
                  width: size,
                  height: size,
                  decoration: BoxDecoration(
                    color: logoColor,
                    shape: BoxShape.circle,
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        width: size * 0.8,
                        height: size * 0.8,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.3),
                          shape: BoxShape.circle,
                        ),
                      ),
                      Container(
                        width: size * 0.5,
                        height: size * 0.5,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                      ),
                      Container(
                        width: size * 0.2,
                        height: size * 0.2,
                        decoration: BoxDecoration(
                          color: logoColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
        
        // Text if requested
        if (showText) ...[
          const SizedBox(height: 8),
          Text(
            text ?? 'Beacon',
            style: TextStyle(
              fontSize: size * 0.25,
              fontWeight: FontWeight.bold,
              color: logoColor,
            ),
          ),
        ],
      ],
    );
  }
}

class BeaconAppIcon extends StatelessWidget {
  final double size;
  
  const BeaconAppIcon({
    super.key,
    this.size = 1024.0,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF00796B), // Teal
            const Color(0xFF004D40), // Dark Teal
          ],
        ),
        borderRadius: BorderRadius.circular(size * 0.2),
      ),
      child: Center(
        child: BeaconLogo(
          size: size * 0.6,
          color: Colors.white,
        ),
      ),
    );
  }
}

class BeaconHeaderLogo extends StatelessWidget {
  final double height;
  
  const BeaconHeaderLogo({
    super.key,
    this.height = 48.0,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        BeaconLogo(
          size: height,
          color: Colors.white,
        ),
        const SizedBox(width: 12),
        Text(
          'Beacon of New Beginnings',
          style: TextStyle(
            fontSize: height * 0.35,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ],
    );
  }
}