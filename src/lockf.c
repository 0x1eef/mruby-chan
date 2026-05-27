/* mruby-chan — POSIX lockf() bindings for mruby */
#include <mruby.h>
#include <mruby/class.h>
#include <mruby/error.h>
#include <errno.h>
#include <unistd.h>

static mrb_value
mrb_chan_lockf(mrb_state *mrb, mrb_value self)
{
  mrb_int fd, cmd, len;
  mrb_get_args(mrb, "iii", &fd, &cmd, &len);
  int rv = lockf((int)fd, (int)cmd, (off_t)len);
  if (rv == -1) {
    mrb_sys_fail(mrb, "lockf");
  }
  return mrb_true_value();
}

static mrb_value
mrb_chan_lockf_nonblock(mrb_state *mrb, mrb_value self)
{
  mrb_int fd, cmd, len;
  mrb_get_args(mrb, "iii", &fd, &cmd, &len);
  int rv = lockf((int)fd, (int)cmd, (off_t)len);
  if (rv == -1) {
    if (errno == EAGAIN || errno == EACCES || errno == EWOULDBLOCK) {
      return mrb_false_value();
    }
    mrb_sys_fail(mrb, "lockf");
  }
  return mrb_true_value();
}

void
mrb_mruby_chan_gem_init(mrb_state *mrb)
{
  struct RClass *chan = mrb_define_module(mrb, "Chan");

  mrb_define_module_function(mrb, chan, "lockf",           mrb_chan_lockf,          MRB_ARGS_REQ(3));
  mrb_define_module_function(mrb, chan, "lockf_nonblock",  mrb_chan_lockf_nonblock,  MRB_ARGS_REQ(3));

  mrb_define_const(mrb, chan, "F_LOCK",   mrb_fixnum_value(F_LOCK));
  mrb_define_const(mrb, chan, "F_TLOCK",  mrb_fixnum_value(F_TLOCK));
  mrb_define_const(mrb, chan, "F_ULOCK",  mrb_fixnum_value(F_ULOCK));
  mrb_define_const(mrb, chan, "F_TEST",   mrb_fixnum_value(F_TEST));
}

void
mrb_mruby_chan_gem_final(mrb_state *mrb)
{
}
