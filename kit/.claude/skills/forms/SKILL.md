---
name: forms
description: Build accessible, validated forms — react-hook-form + zod (or the repo's choice), DS field components, server error mapping, submit/pending/success states, Next server actions with useActionState, and tests. Use for any form, filter panel, login/signup, checkout, create/edit screens.
---

# Forms

## Default: react-hook-form + zod (if both are in the repo, or the user OKs them)
```tsx
import { useForm } from 'react-hook-form';
import { zodResolver } from '@hookform/resolvers/zod';
import { z } from 'zod';
import { Button, TextField } from '@scope/ui';

const schema = z.object({
  name: z.string().trim().min(2, 'At least 2 characters'),
  email: z.string().email('Invalid e-mail'),
  age: z.coerce.number().int().min(18, 'Must be 18+'),
});
type FormValues = z.infer<typeof schema>;

export function SignupForm({ onSubmit }: { onSubmit: (v: FormValues) => Promise<void> }) {
  const { register, handleSubmit, setError, formState: { errors, isSubmitting, isSubmitSuccessful } } =
    useForm<FormValues>({ resolver: zodResolver(schema), mode: 'onBlur' });

  const submit = handleSubmit(async (values) => {
    try {
      await onSubmit(values);
    } catch (e) {
      if (e instanceof ApiError && e.status === 409) setError('email', { message: 'E-mail already registered' });
      else setError('root', { message: 'Something went wrong. Try again.' });
    }
  });

  return (
    <form onSubmit={submit} noValidate>
      <TextField label="Name" {...register('name')} error={errors.name?.message} />
      <TextField label="E-mail" type="email" autoComplete="email" {...register('email')} error={errors.email?.message} />
      <TextField label="Age" inputMode="numeric" {...register('age')} error={errors.age?.message} />
      {errors.root && <p role="alert">{errors.root.message}</p>}
      <Button type="submit" loading={isSubmitting}>Create account</Button>
      {isSubmitSuccessful && <p role="status">Account created</p>}
    </form>
  );
}
```
- DS field components must spread native props and forward the ref (see `ds-component`) so `register` works. For non-native inputs (Select, DatePicker) use `<Controller>`.
- Keep the same zod schema on the server (shared package in a monorepo), which gives you single-source validation.

## Without RHF (no dependency approved)
Controlled state + `schema.safeParse(values)` on submit, mapping `error.flatten().fieldErrors` to the fields. It's fine for small forms. Say that RHF reduces re-renders and boilerplate as the form grows.

## Next server actions
`useActionState(action, initialState)` + `<form action={formAction}>`, validated with zod on the server (see `api-layer/references/next-server.md`). The pending state comes from the third tuple item or from `useFormStatus` in the submit button.

## a11y checklist
- [ ] every input has a visible label; errors are linked via `aria-describedby`, and `aria-invalid` is set
- [ ] on a submit with errors, focus goes to the first invalid field (RHF's `shouldFocusError` default)
- [ ] the submit button is not disabled before the first attempt (users need to discover the errors); disable it only while pending
- [ ] correct `type`, `autoComplete` and `inputMode`

## Tests
Fill fields via `userEvent.type(screen.getByLabelText(/e-mail/i), ...)`, submit, and assert the error messages by role/text and the `onSubmit` call args.
