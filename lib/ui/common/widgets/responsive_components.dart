import 'package:flutter/material.dart';
import '../../../theme/theme.dart';

/// Responsive wrapper that adapts to different screen sizes
class ResponsiveWrapper extends StatelessWidget {
  final Widget child;
  final EdgeInsets? mobilePadding;
  final EdgeInsets? tabletPadding;
  final EdgeInsets? desktopPadding;
  final double? maxWidth;
  final bool centerContent;

  const ResponsiveWrapper({
    super.key,
    required this.child,
    this.mobilePadding,
    this.tabletPadding,
    this.desktopPadding,
    this.maxWidth,
    this.centerContent = true,
  });

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isMobile = ResponsiveHelper.isMobile(context);
    final isTablet = width >= ResponsiveBreakpoints.tabletSmall && 
                    width < ResponsiveBreakpoints.tabletLarge;
    final isDesktop = width >= ResponsiveBreakpoints.tabletLarge;

    EdgeInsets padding;
    if (isDesktop && desktopPadding != null) {
      padding = desktopPadding!;
    } else if (isTablet && tabletPadding != null) {
      padding = tabletPadding!;
    } else if (isMobile && mobilePadding != null) {
      padding = mobilePadding!;
    } else {
      padding = ResponsiveHelper.getResponsivePadding(
        context,
        mobile: const EdgeInsets.all(16),
        tablet: const EdgeInsets.all(24),
        desktop: const EdgeInsets.all(32),
      );
    }

    Widget content = Padding(
      padding: padding,
      child: child,
    );

    if (maxWidth != null) {
      content = ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth!),
        child: content,
      );
    }

    if (centerContent) {
      content = Center(child: content);
    }

    return content;
  }
}

/// Responsive card that adapts margins and padding
class ResponsiveCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? margin;
  final EdgeInsets? padding;
  final double? elevation;
  final Color? color;
  final BorderRadius? borderRadius;
  final VoidCallback? onTap;

  const ResponsiveCard({
    super.key,
    required this.child,
    this.margin,
    this.padding,
    this.elevation,
    this.color,
    this.borderRadius,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveHelper.isMobile(context);
    
    final cardMargin = margin ?? EdgeInsets.symmetric(
      horizontal: isMobile ? 8 : 16,
      vertical: isMobile ? 4 : 8,
    );
    
    final cardPadding = padding ?? EdgeInsets.all(
      isMobile ? 12 : 16,
    );

    return Card(
      margin: cardMargin,
      elevation: elevation ?? (isMobile ? 2 : 3),
      color: color,
      shape: RoundedRectangleBorder(
        borderRadius: borderRadius ?? BorderRadius.circular(
          isMobile ? 12 : 16,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: borderRadius ?? BorderRadius.circular(
          isMobile ? 12 : 16,
        ),
        child: Padding(
          padding: cardPadding,
          child: child,
        ),
      ),
    );
  }
}

/// Responsive text that scales with screen size
class ResponsiveText extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;
  final double? mobileFontSize;
  final double? tabletFontSize;
  final double? desktopFontSize;

  const ResponsiveText(
    this.text, {
    super.key,
    this.style,
    this.textAlign,
    this.maxLines,
    this.overflow,
    this.mobileFontSize,
    this.tabletFontSize,
    this.desktopFontSize,
  });

  @override
  Widget build(BuildContext context) {
    final baseStyle = style ?? const TextStyle();
    final responsiveFontSize = ResponsiveHelper.getResponsiveFontSize(
      context,
      mobile: mobileFontSize ?? baseStyle.fontSize ?? 14,
      tablet: tabletFontSize ?? (baseStyle.fontSize ?? 14) + 2,
      desktop: desktopFontSize ?? (baseStyle.fontSize ?? 14) + 4,
    );

    return Text(
      text,
      style: baseStyle.copyWith(fontSize: responsiveFontSize),
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,
    );
  }
}

/// Responsive button that adapts size and padding
class ResponsiveButton extends StatelessWidget {
  final Widget child;
  final VoidCallback? onPressed;
  final ButtonStyle? style;
  final bool isFullWidth;
  final double? mobileHeight;
  final double? tabletHeight;
  final double? desktopHeight;

  const ResponsiveButton({
    super.key,
    required this.child,
    this.onPressed,
    this.style,
    this.isFullWidth = false,
    this.mobileHeight,
    this.tabletHeight,
    this.desktopHeight,
  });

  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveHelper.isMobile(context);
    final isTablet = MediaQuery.of(context).size.width >= ResponsiveBreakpoints.tabletSmall;
    
    double height;
    if (isMobile && mobileHeight != null) {
      height = mobileHeight!;
    } else if (isTablet && tabletHeight != null) {
      height = tabletHeight!;
    } else if (desktopHeight != null) {
      height = desktopHeight!;
    } else {
      height = isMobile ? 44 : 48;
    }

    Widget button = ElevatedButton(
      onPressed: onPressed,
      style: style,
      child: child,
    );

    if (isFullWidth) {
      button = SizedBox(
        width: double.infinity,
        height: height,
        child: button,
      );
    } else {
      button = SizedBox(
        height: height,
        child: button,
      );
    }

    return button;
  }
}

/// Responsive grid that adapts columns based on screen size
class ResponsiveGrid extends StatelessWidget {
  final List<Widget> children;
  final int? mobileColumns;
  final int? tabletColumns;
  final int? desktopColumns;
  final double? spacing;
  final double? runSpacing;
  final EdgeInsets? padding;

  const ResponsiveGrid({
    super.key,
    required this.children,
    this.mobileColumns,
    this.tabletColumns,
    this.desktopColumns,
    this.spacing,
    this.runSpacing,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isMobile = ResponsiveHelper.isMobile(context);
    final isTablet = width >= ResponsiveBreakpoints.tabletSmall && 
                    width < ResponsiveBreakpoints.tabletLarge;
    final isDesktop = width >= ResponsiveBreakpoints.tabletLarge;

    int columns;
    if (isDesktop && desktopColumns != null) {
      columns = desktopColumns!;
    } else if (isTablet && tabletColumns != null) {
      columns = tabletColumns!;
    } else if (isMobile && mobileColumns != null) {
      columns = mobileColumns!;
    } else {
      columns = isMobile ? 2 : (isTablet ? 3 : 4);
    }

    return Padding(
      padding: padding ?? EdgeInsets.zero,
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: columns,
          crossAxisSpacing: spacing ?? 12,
          mainAxisSpacing: runSpacing ?? 12,
          childAspectRatio: 1.0,
        ),
        itemCount: children.length,
        itemBuilder: (context, index) => children[index],
      ),
    );
  }
}

/// Responsive list tile optimized for mobile
class ResponsiveListTile extends StatelessWidget {
  final Widget? leading;
  final Widget? title;
  final Widget? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final EdgeInsets? contentPadding;
  final bool isThreeLine;

  const ResponsiveListTile({
    super.key,
    this.leading,
    this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.contentPadding,
    this.isThreeLine = false,
  });

  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveHelper.isMobile(context);
    
    final tilePadding = contentPadding ?? EdgeInsets.symmetric(
      horizontal: isMobile ? 16 : 24,
      vertical: isMobile ? 8 : 12,
    );

    return ListTile(
      leading: leading,
      title: title,
      subtitle: subtitle,
      trailing: trailing,
      onTap: onTap,
      contentPadding: tilePadding,
      isThreeLine: isThreeLine,
      minVerticalPadding: isMobile ? 4 : 8,
    );
  }
}

/// Responsive container that adapts to screen size
class ResponsiveContainer extends StatelessWidget {
  final Widget child;
  final double? width;
  final double? height;
  final EdgeInsets? padding;
  final EdgeInsets? margin;
  final Color? color;
  final BorderRadius? borderRadius;
  final BoxDecoration? decoration;
  final Alignment? alignment;

  const ResponsiveContainer({
    super.key,
    required this.child,
    this.width,
    this.height,
    this.padding,
    this.margin,
    this.color,
    this.borderRadius,
    this.decoration,
    this.alignment,
  });

  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveHelper.isMobile(context);
    
    final containerPadding = padding ?? EdgeInsets.all(
      isMobile ? 12 : 16,
    );
    
    final containerMargin = margin ?? EdgeInsets.symmetric(
      horizontal: isMobile ? 8 : 16,
      vertical: isMobile ? 4 : 8,
    );

    return Container(
      width: width,
      height: height,
      padding: containerPadding,
      margin: containerMargin,
      decoration: decoration ?? BoxDecoration(
        color: color,
        borderRadius: borderRadius ?? BorderRadius.circular(
          isMobile ? 8 : 12,
        ),
      ),
      alignment: alignment,
      child: child,
    );
  }
}

/// Responsive spacing that adapts to screen size
class ResponsiveSpacing extends StatelessWidget {
  final double mobileSpacing;
  final double? tabletSpacing;
  final double? desktopSpacing;
  final Axis direction;

  const ResponsiveSpacing({
    super.key,
    required this.mobileSpacing,
    this.tabletSpacing,
    this.desktopSpacing,
    this.direction = Axis.vertical,
  });

  @override
  Widget build(BuildContext context) {
    final spacing = ResponsiveHelper.getResponsiveFontSize(
      context,
      mobile: mobileSpacing,
      tablet: tabletSpacing ?? mobileSpacing * 1.2,
      desktop: desktopSpacing ?? mobileSpacing * 1.5,
    );

    if (direction == Axis.vertical) {
      return SizedBox(height: spacing);
    } else {
      return SizedBox(width: spacing);
    }
  }
}
