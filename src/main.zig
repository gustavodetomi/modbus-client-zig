const std = @import("std");
const builtin = @import("builtin");
const c = @cImport({
    @cInclude("gtk/gtk.h");
});

// Estrutura para dados da aplicação
const AppData = struct {
    window: *c.GtkWidget,
    label: *c.GtkWidget,
    button: *c.GtkWidget,
    entry: *c.GtkWidget,
    counter: i32,
};

// Callback para o botão "Clique Aqui"
fn on_button_clicked(widget: *c.GtkWidget, user_data: c.gpointer) callconv(.C) void {
    _ = widget; // parâmetro não usado

    const app_data: *AppData = @ptrCast(@alignCast(user_data));
    app_data.counter += 1;

    // Criar texto atualizado
    var buffer: [256]u8 = undefined;
    const text = std.fmt.bufPrintZ(buffer[0..], "Botão clicado {d} vezes!", .{app_data.counter}) catch "Erro ao formatar texto";

    // Atualizar label
    c.gtk_label_set_text(@ptrCast(app_data.label), text.ptr);

    // Mostrar mensagem no console
    std.debug.print("Botão clicado! Contador: {d}\n", .{app_data.counter});
}

// Callback para o botão "Limpar"
fn on_clear_clicked(widget: *c.GtkWidget, user_data: c.gpointer) callconv(.C) void {
    _ = widget; // parâmetro não usado

    const app_data: *AppData = @ptrCast(@alignCast(user_data));
    app_data.counter = 0;

    // Resetar label
    c.gtk_label_set_text(@ptrCast(app_data.label), "Olá, GTK4 com Zig! Clique no botão abaixo.");

    // Limpar campo de texto
    c.gtk_editable_set_text(@ptrCast(app_data.entry), "");

    std.debug.print("Contador resetado!\n", .{});
}

// Callback para mudança no campo de texto
fn on_text_changed(widget: *c.GtkWidget, user_data: c.gpointer) callconv(.C) void {
    _ = user_data; // parâmetro não usado

    const text = c.gtk_editable_get_text(@ptrCast(widget));
    if (text != null) {
        const text_len = std.mem.len(text);
        std.debug.print("Texto alterado: {s} (tamanho: {d})\n", .{ text[0..text_len], text_len });
    }
}

// Callback para fechar a aplicação
fn on_window_close(widget: *c.GtkWidget, user_data: c.gpointer) callconv(.C) void {
    _ = widget; // parâmetro não usado
    _ = user_data; // parâmetro não usado

    std.debug.print("Fechando aplicação...\n", .{});
    c.g_application_quit(@ptrCast(c.g_application_get_default()));
}

// Callback de ativação da aplicação
fn activate(app: *c.GtkApplication, user_data: c.gpointer) callconv(.C) void {
    _ = user_data; // parâmetro não usado

    std.debug.print("Ativando aplicação GTK4...\n", .{});

    // Alocar dados da aplicação
    const allocator = std.heap.page_allocator;
    const app_data = allocator.create(AppData) catch {
        std.debug.print("Erro ao alocar memória para AppData\n", .{});
        return;
    };

    // Criar janela principal
    app_data.window = c.gtk_application_window_new(app);
    c.gtk_window_set_title(@ptrCast(app_data.window), "GTK4 com Zig - Aplicação Demo");
    c.gtk_window_set_default_size(@ptrCast(app_data.window), 400, 300);
    c.gtk_window_set_resizable(@ptrCast(app_data.window), 1);

    // Conectar sinal de fechamento
    _ = c.g_signal_connect_data(app_data.window, "destroy", @ptrCast(&on_window_close), app_data, null, 0);

    // Criar container principal (Box vertical)
    const main_box = c.gtk_box_new(c.GTK_ORIENTATION_VERTICAL, 10);
    c.gtk_widget_set_margin_top(main_box, 20);
    c.gtk_widget_set_margin_bottom(main_box, 20);
    c.gtk_widget_set_margin_start(main_box, 20);
    c.gtk_widget_set_margin_end(main_box, 20);

    // Criar título
    const title_label = c.gtk_label_new("🎉 Aplicação GTK4 com Zig 🎉");
    c.gtk_label_set_markup(@ptrCast(title_label), "<span size='x-large' weight='bold'>🎉 Aplicação GTK4 com Zig 🎉</span>");
    c.gtk_widget_set_halign(title_label, c.GTK_ALIGN_CENTER);
    c.gtk_box_append(@ptrCast(main_box), title_label);

    // Criar separador
    const separator1 = c.gtk_separator_new(c.GTK_ORIENTATION_HORIZONTAL);
    c.gtk_box_append(@ptrCast(main_box), separator1);

    // Criar label principal
    app_data.counter = 0;
    app_data.label = c.gtk_label_new("Olá, GTK4 com Zig! Clique no botão abaixo.");
    c.gtk_widget_set_halign(app_data.label, c.GTK_ALIGN_CENTER);
    c.gtk_label_set_wrap(@ptrCast(app_data.label), 1);
    c.gtk_box_append(@ptrCast(main_box), app_data.label);

    // Criar campo de entrada de texto
    app_data.entry = c.gtk_entry_new();
    c.gtk_entry_set_placeholder_text(@ptrCast(app_data.entry), "Digite algo aqui...");
    c.gtk_widget_set_halign(app_data.entry, c.GTK_ALIGN_CENTER);
    c.gtk_widget_set_size_request(app_data.entry, 250, -1);

    // Conectar sinal de mudança de texto
    _ = c.g_signal_connect_data(app_data.entry, "changed", @ptrCast(&on_text_changed), app_data, null, 0);
    c.gtk_box_append(@ptrCast(main_box), app_data.entry);

    // Criar container para botões (Box horizontal)
    const button_box = c.gtk_box_new(c.GTK_ORIENTATION_HORIZONTAL, 10);
    c.gtk_widget_set_halign(button_box, c.GTK_ALIGN_CENTER);

    // Criar botão principal
    app_data.button = c.gtk_button_new_with_label("🔄 Clique Aqui");
    c.gtk_widget_set_size_request(app_data.button, 120, 40);

    // Conectar callback do botão
    _ = c.g_signal_connect_data(app_data.button, "clicked", @ptrCast(&on_button_clicked), app_data, null, 0);
    c.gtk_box_append(@ptrCast(button_box), app_data.button);

    // Criar botão de limpar
    const clear_button = c.gtk_button_new_with_label("🗑️ Limpar");
    c.gtk_widget_set_size_request(clear_button, 120, 40);

    // Conectar callback do botão limpar
    _ = c.g_signal_connect_data(clear_button, "clicked", @ptrCast(&on_clear_clicked), app_data, null, 0);
    c.gtk_box_append(@ptrCast(button_box), clear_button);

    c.gtk_box_append(@ptrCast(main_box), button_box);

    // Criar outro separador
    const separator2 = c.gtk_separator_new(c.GTK_ORIENTATION_HORIZONTAL);
    c.gtk_box_append(@ptrCast(main_box), separator2);

    // Criar informações do sistema
    const info_label = c.gtk_label_new(null);
    var info_buffer: [512]u8 = undefined;
    const info_text = std.fmt.bufPrintZ(info_buffer[0..], "<small><i>Sistema: {s} | Arquitetura: {s} | Zig versão: 0.14</i></small>", .{ @tagName(builtin.target.os.tag), @tagName(builtin.target.cpu.arch) }) catch "Informações do sistema";

    c.gtk_label_set_markup(@ptrCast(info_label), info_text.ptr);
    c.gtk_widget_set_halign(info_label, c.GTK_ALIGN_CENTER);
    c.gtk_box_append(@ptrCast(main_box), info_label);

    // Adicionar container à janela
    c.gtk_window_set_child(@ptrCast(app_data.window), main_box);

    // Mostrar janela
    c.gtk_window_present(@ptrCast(app_data.window));

    std.debug.print("Janela GTK4 criada e apresentada!\n", .{});
}

// Função principal
pub fn main() !void {
    std.debug.print("Iniciando aplicação GTK4 com Zig...\n", .{});

    // Criar aplicação GTK
    const app = c.gtk_application_new("com.example.zig-gtk4", c.G_APPLICATION_DEFAULT_FLAGS);
    if (app == null) {
        std.debug.print("Erro ao criar aplicação GTK!\n", .{});
        return;
    }
    defer c.g_object_unref(app);

    // Conectar sinal de ativação
    _ = c.g_signal_connect_data(app, "activate", @ptrCast(&activate), null, null, 0);

    // Executar aplicação
    const status = c.g_application_run(@ptrCast(app), 0, null);

    std.debug.print("Aplicação finalizada com status: {d}\n", .{status});
}
