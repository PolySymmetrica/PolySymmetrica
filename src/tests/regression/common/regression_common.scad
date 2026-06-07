use <regression_digits.scad>

REG_FACE_COLOR = "lightskyblue";
REG_EDGE_COLOR = "tomato";
REG_VERTEX_COLOR = "gold";
REG_SOLID_COLOR = "gainsboro";
REG_LABEL_SIZE = 2.4;
REG_LABEL_H = 0.12;
REG_LABEL_FONT = "Liberation Sans:style=Bold";

module reg_list_tests(tests) {
    echo(str("REGRESSION_T_MAX=", len(tests)));
    for (i = [0:1:len(tests) - 1])
        echo(str("REGRESSION_TEST=", i, " ", tests[i][0]));

    cube([0.01, 0.01, 0.01], center = true);
}

module reg_panel_label_num(n, size = REG_LABEL_SIZE, h = REG_LABEL_H) {
    reg_label_num(n, size = size, h = h, backing = true);
}

module reg_text_label(s, size = REG_LABEL_SIZE, h = REG_LABEL_H, font = REG_LABEL_FONT) {
    color("white")
        translate([0, 0, -h * 0.15])
            linear_extrude(height = h * 0.35)
                offset(size * 0.09)
                    text(str(s), size = size, font = font, halign = "center", valign = "center");

    color("black")
        linear_extrude(height = h)
            text(str(s), size = size, font = font, halign = "center", valign = "center");
}
