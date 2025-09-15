import 'package:flutter/material.dart';
import '../../theme/theme.dart';

/// A responsive wrapper that provides mobile-optimized layouts
class ResponsiveWrapper extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final bool scrollable;
  final bool safeArea;

  const ResponsiveWrapper({
    super.key,
    required this.child,
    this.padding,
    this.scrollable = true,
    this.safeArea = true,
  });

  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveHelper.isMobile(context);
    final isSmallMobile = ResponsiveHelper.isSmallMobile(context);
    
    // Calculate responsive padding
    final responsivePadding = padding ?? ResponsiveHelper.getResponsivePadding(
      context,
      mobile: EdgeInsets.symmetric(
        horizontal: isSmallMobile ? 8 : 12,
        vertical: 8,
      ),
      tablet: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      desktop: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
    );

    Widget content = Padding(
      padding: responsivePadding,
      child: child,
    );

    if (scrollable) {
      content = SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: content,
      );
    }

    if (safeArea) {
      content = SafeArea(
        child: content,
      );
    }

    return content;
  }
}

/// A responsive card that adapts to screen size
class ResponsiveCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? margin;
  final EdgeInsets? padding;
  final Color? color;
  final double? elevation;

  const ResponsiveCard({
    super.key,
    required this.child,
    this.margin,
    this.padding,
    this.color,
    this.elevation,
  });

  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveHelper.isMobile(context);
    final isSmallMobile = ResponsiveHelper.isSmallMobile(context);
    
    return Card(
      color: color,
      elevation: elevation ?? (isMobile ? 2 : 3),
      margin: margin ?? EdgeInsets.symmetric(
        horizontal: isSmallMobile ? 4 : 8,
        vertical: 4,
      ),
      child: Padding(
        padding: padding ?? EdgeInsets.all(
          isSmallMobile ? 12 : (isMobile ? 16 : 20),
        ),
        child: child,
      ),
    );
  }
}

/// A responsive text widget that adapts font size based on screen size
class ResponsiveText extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;

  const ResponsiveText(
    this.text, {
    super.key,
    this.style,
    this.textAlign,
    this.maxLines,
    this.overflow,
  });

  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveHelper.isMobile(context);
    final isSmallMobile = ResponsiveHelper.isSmallMobile(context);
    
    // Calculate responsive font size
    double fontSize = style?.fontSize ?? 14;
    if (isSmallMobile) {
      fontSize = fontSize * 0.9;
    } else if (isMobile) {
      fontSize = fontSize * 0.95;
    }
    
    return Text(
      text,
      style: (style ?? const TextStyle()).copyWith(fontSize: fontSize),
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow ?? TextOverflow.ellipsis,
    );
  }
}

/// A responsive button that adapts size based on screen
class ResponsiveButton extends StatelessWidget {
  final Widget child;
  final VoidCallback? onPressed;
  final ButtonStyle? style;
  final bool isOutlined;
  final bool isText;

  const ResponsiveButton({
    super.key,
    required this.child,
    this.onPressed,
    this.style,
    this.isOutlined = false,
    this.isText = false,
  });

  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveHelper.isMobile(context);
    final isSmallMobile = ResponsiveHelper.isSmallMobile(context);
    
    // Calculate responsive button size
    final buttonHeight = isSmallMobile ? 40 : (isMobile ? 44 : 48);
    final horizontalPadding = isSmallMobile ? 12 : (isMobile ? 16 : 20);
    
    final buttonStyle = (style ?? const ButtonStyle()).copyWith(
      minimumSize: WidgetStateProperty.all(Size(0, buttonHeight)),
      padding: WidgetStateProperty.all(
        EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 8),
      ),
    );

    if (isText) {
      return TextButton(
        onPressed: onPressed,
        style: buttonStyle,
        child: child,
      );
    } else if (isOutlined) {
      return OutlinedButton(
        onPressed: onPressed,
        style: buttonStyle,
        child: child,
      );
    } else {
      return ElevatedButton(
        onPressed: onPressed,
        style: buttonStyle,
        child: child,
      );
    }
  }
}

/// A responsive grid that adapts columns based on screen size
class ResponsiveGrid extends StatelessWidget {
  final List<Widget> children;
  final double spacing;
  final double runSpacing;
  final int? maxColumns;

  const ResponsiveGrid({
    super.key,
    required this.children,
    this.spacing = 8.0,
    this.runSpacing = 8.0,
    this.maxColumns,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = ResponsiveHelper.isMobile(context);
    final isSmallMobile = ResponsiveHelper.isSmallMobile(context);
    
    // Calculate number of columns based on screen size
    int columns = 1;
    if (isSmallMobile) {
      columns = 1;
    } else if (isMobile) {
      columns = 2;
    } else {
      columns = 3;
    }
    
    if (maxColumns != null && columns > maxColumns!) {
      columns = maxColumns!;
    }
    
    // Calculate item width
    final itemWidth = (screenWidth - (spacing * (columns - 1)) - 32) / columns;
    
    return Wrap(
      spacing: spacing,
      runSpacing: runSpacing,
      children: children.map((child) => SizedBox(
        width: itemWidth,
        child: child,
      )).toList(),
    );
  }
}

/// A responsive list tile that adapts to screen size
class ResponsiveListTile extends StatelessWidget {
  final Widget? leading;
  final Widget? title;
  final Widget? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final EdgeInsets? contentPadding;

  const ResponsiveListTile({
    super.key,
    this.leading,
    this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.contentPadding,
  });

  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveHelper.isMobile(context);
    final isSmallMobile = ResponsiveHelper.isSmallMobile(context);
    
    return ListTile(
      leading: leading,
      title: title,
      subtitle: subtitle,
      trailing: trailing,
      onTap: onTap,
      contentPadding: contentPadding ?? EdgeInsets.symmetric(
        horizontal: isSmallMobile ? 8 : (isMobile ? 12 : 16),
        vertical: 4,
      ),
      minVerticalPadding: isSmallMobile ? 4 : 8,
    );
  }
}
