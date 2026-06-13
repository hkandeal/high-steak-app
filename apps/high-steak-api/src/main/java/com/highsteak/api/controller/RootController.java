package com.highsteak.api.controller;

import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.servlet.view.RedirectView;

@Controller
public class RootController {

    @GetMapping({"/", ""})
    RedirectView root() {
        return new RedirectView("swagger-ui.html");
    }
}
